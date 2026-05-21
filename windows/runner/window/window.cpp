// Subset port of bitsdojo_window 0.1.6 (MIT, Copyright 2020-2021 Bogdan
// Hobeanu). See third_party/bitsdojo_window/LICENSE. Stripped of unused
// features (max_size, restoreByMove, window_cut_on_maximize, dynamic DPI
// loader) and the method-channel/plugin wiring.

#include "window.h"

#include <windowsx.h>
#include <dwmapi.h>
#include <math.h>

namespace waydir_window {

namespace {

HWND g_flutter_window = nullptr;
HWND g_flutter_child_window = nullptr;
HHOOK g_creation_hook = nullptr;
BOOL g_has_custom_frame = FALSE;
BOOL g_visible_on_startup = TRUE;
BOOL g_window_can_be_shown = FALSE;
BOOL g_during_minimize = FALSE;
SIZE g_min_size = {0, 0};

LRESULT CALLBACK MainWindowProc(HWND window, UINT message, WPARAM wparam,
                                LPARAM lparam, UINT_PTR subclass_id,
                                DWORD_PTR ref_data);
LRESULT CALLBACK ChildWindowProc(HWND window, UINT message, WPARAM wparam,
                                 LPARAM lparam, UINT_PTR subclass_id,
                                 DWORD_PTR ref_data);

LRESULT CALLBACK CreationHookProc(int code, WPARAM wparam, LPARAM lparam) {
  if (code == HCBT_CREATEWND) {
    auto create_params = reinterpret_cast<CBT_CREATEWND*>(lparam);
    if (create_params && create_params->lpcs &&
        create_params->lpcs->lpCreateParams) {
      auto class_name = create_params->lpcs->lpszClass;
      if (wcscmp(class_name, L"FLUTTER_RUNNER_WIN32_WINDOW") == 0) {
        g_flutter_window = reinterpret_cast<HWND>(wparam);
        SetWindowSubclass(g_flutter_window, MainWindowProc, 1, 0);
      } else if (wcscmp(class_name, L"FLUTTERVIEW") == 0) {
        g_flutter_child_window = reinterpret_cast<HWND>(wparam);
        SetWindowSubclass(g_flutter_child_window, ChildWindowProc, 1, 0);
      }
    }
  }
  if (g_flutter_window && g_flutter_child_window && g_creation_hook) {
    UnhookWindowsHookEx(g_creation_hook);
    g_creation_hook = nullptr;
  }
  return CallNextHookEx(nullptr, code, wparam, lparam);
}

void InstallCreationHook() {
  g_creation_hook = SetWindowsHookEx(WH_CBT, CreationHookProc, nullptr,
                                     GetCurrentThreadId());
}

void ForceChildRefresh() {
  if (!g_flutter_child_window) return;
  RECT rc;
  GetClientRect(g_flutter_window, &rc);
  int width = rc.right - rc.left;
  int height = rc.bottom - rc.top;
  SetWindowPos(g_flutter_child_window, nullptr, 0, 0, width + 1, height + 1,
               SWP_NOMOVE | SWP_NOACTIVATE);
  SetWindowPos(g_flutter_child_window, nullptr, 0, 0, width, height,
               SWP_NOMOVE | SWP_NOACTIVATE);
}

int GetResizeMargin(HWND window) {
  UINT dpi = GetDpiForWindow(window);
  int border = GetSystemMetricsForDpi(SM_CXSIZEFRAME, dpi);
  int padding = GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
  if (IsZoomed(window)) return padding;
  return border + padding;
}

void ExtendIntoClientArea(HWND hwnd) {
  MARGINS margins = {0, 0, 1, 0};
  DwmExtendFrameIntoClientArea(hwnd, &margins);
}

LRESULT HandleHitTest(HWND window, LPARAM lparam) {
  if (IsZoomed(g_flutter_window)) return HTCLIENT;
  POINT pt = {GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam)};
  ScreenToClient(window, &pt);
  RECT rc;
  GetClientRect(window, &rc);
  int margin = GetResizeMargin(window);
  if (pt.y < margin) {
    if (pt.x < margin) return HTTOPLEFT;
    if (pt.x > rc.right - margin) return HTTOPRIGHT;
    return HTTOP;
  }
  if (pt.y > rc.bottom - margin) {
    if (pt.x < margin) return HTBOTTOMLEFT;
    if (pt.x > rc.right - margin) return HTBOTTOMRIGHT;
    return HTBOTTOM;
  }
  if (pt.x < margin) return HTLEFT;
  if (pt.x > rc.right - margin) return HTRIGHT;
  return HTCLIENT;
}

double GetScaleFactor(HWND window) {
  return GetDpiForWindow(window) / 96.0;
}

LRESULT HandleNcCalcSize(HWND window, WPARAM wparam, LPARAM lparam) {
  if (!wparam) return 0;
  auto params = reinterpret_cast<NCCALCSIZE_PARAMS*>(lparam);
  auto initial_rect = params->rgrc[0];
  auto default_result = DefSubclassProc(window, WM_NCCALCSIZE, wparam, lparam);
  if (default_result != 0) return default_result;

  params->rgrc[0] = initial_rect;
  double scale = GetScaleFactor(window);
  int scale_int = static_cast<int>(ceil(scale));

  if (IsZoomed(window)) {
    UINT dpi = GetDpiForWindow(window);
    int frame_x = GetSystemMetricsForDpi(SM_CXSIZEFRAME, dpi);
    int frame_y = GetSystemMetricsForDpi(SM_CYSIZEFRAME, dpi);
    int padding = GetSystemMetricsForDpi(SM_CXPADDEDBORDER, dpi);
    params->rgrc[0].left += frame_x + padding;
    params->rgrc[0].right -= frame_x + padding;
    params->rgrc[0].top += frame_y + padding;
    params->rgrc[0].bottom -= frame_y + padding;
    params->rgrc[0].top -= scale_int + 1;
  } else {
    params->rgrc[0].top -= 1;
  }
  return 0;
}

void GetSizeOnScreen(SIZE* size) {
  double scale = GetDpiForWindow(g_flutter_window) / 96.0;
  size->cx = static_cast<int>(size->cx * scale);
  size->cy = static_cast<int>(size->cy * scale);
}

bool CenterOnMonitorContainingMouse(HWND window, int width, int height) {
  POINT mouse;
  if (!GetCursorPos(&mouse)) return false;
  HMONITOR monitor = MonitorFromPoint(mouse, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info = {};
  info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfoW(monitor, &info)) return false;
  int mon_w = info.rcWork.right - info.rcWork.left;
  int mon_h = info.rcWork.bottom - info.rcWork.top;
  int x = info.rcWork.left + (mon_w - width) / 2;
  int y = info.rcWork.top + (mon_h - height) / 2;
  SetWindowPos(window, nullptr, x, y, 0, 0,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSIZE);
  return true;
}

void AdjustChildWindowSize() {
  RECT rc;
  GetClientRect(g_flutter_window, &rc);
  SetWindowPos(g_flutter_child_window, nullptr, 0, 0, rc.right - rc.left,
               rc.bottom - rc.top, SWP_NOMOVE | SWP_NOACTIVATE);
}

constexpr long kWmDpiChangedBeforeParent = 0x02E2;

void FixDpiScaling() {
  SendMessage(g_flutter_child_window, kWmDpiChangedBeforeParent, 0, 0);
  ForceChildRefresh();
}

LRESULT CALLBACK ChildWindowProc(HWND window, UINT message, WPARAM wparam,
                                 LPARAM lparam, UINT_PTR, DWORD_PTR) {
  switch (message) {
    case WM_CREATE: {
      LRESULT result = DefSubclassProc(window, message, wparam, lparam);
      FixDpiScaling();
      return result;
    }
    case WM_NCHITTEST: {
      if (!g_has_custom_frame) break;
      LRESULT result = HandleHitTest(window, lparam);
      if (result != HTCLIENT) return HTTRANSPARENT;
      break;
    }
  }
  return DefSubclassProc(window, message, wparam, lparam);
}

LRESULT CALLBACK MainWindowProc(HWND window, UINT message, WPARAM wparam,
                                LPARAM lparam, UINT_PTR, DWORD_PTR) {
  switch (message) {
    case WM_ERASEBKGND:
      return 1;
    case WM_NCCREATE: {
      g_flutter_window = window;
      auto style = GetWindowLongPtr(window, GWL_STYLE);
      style |= WS_CLIPCHILDREN;
      SetWindowLongPtr(window, GWL_STYLE, style);
      break;
    }
    case WM_NCHITTEST:
      if (!g_has_custom_frame) break;
      return HandleHitTest(window, lparam);
    case WM_NCCALCSIZE:
      if (!g_has_custom_frame) break;
      return HandleNcCalcSize(window, wparam, lparam);
    case WM_CREATE: {
      auto create_struct = reinterpret_cast<CREATESTRUCT*>(lparam);
      LRESULT result = DefSubclassProc(window, message, wparam, lparam);
      if (g_has_custom_frame) {
        ExtendIntoClientArea(window);
        SetWindowPos(window, nullptr, 0, 0, 0, 0,
                     SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE |
                         SWP_DRAWFRAME);
      }
      CenterOnMonitorContainingMouse(window, create_struct->cx,
                                     create_struct->cy);
      if (g_visible_on_startup) {
        setWindowCanBeShown(true);
        ForceChildRefresh();
      }
      return result;
    }
    case WM_DPICHANGED:
      ForceChildRefresh();
      break;
    case WM_SIZE:
      if (g_during_minimize) return 0;
      break;
    case WM_SYSCOMMAND: {
      if (wparam == SC_MINIMIZE) g_during_minimize = TRUE;
      LRESULT result = DefSubclassProc(window, message, wparam, lparam);
      g_during_minimize = FALSE;
      return result;
    }
    case WM_WINDOWPOSCHANGING: {
      auto win_pos = reinterpret_cast<WINDOWPOS*>(lparam);
      BOOL is_show = (win_pos->flags & SWP_SHOWWINDOW) == SWP_SHOWWINDOW;
      if (is_show && !g_window_can_be_shown && !g_visible_on_startup) {
        win_pos->flags &= ~SWP_SHOWWINDOW;
      }
      break;
    }
    case WM_WINDOWPOSCHANGED: {
      auto win_pos = reinterpret_cast<WINDOWPOS*>(lparam);
      bool is_resize = !(win_pos->flags & SWP_NOSIZE);
      if (!g_window_can_be_shown) break;
      if (is_resize && !g_during_minimize && win_pos->cx != 0) {
        AdjustChildWindowSize();
      }
      break;
    }
    case WM_GETMINMAXINFO: {
      auto info = reinterpret_cast<MINMAXINFO*>(lparam);
      if (g_min_size.cx != 0 && g_min_size.cy != 0) {
        SIZE size = g_min_size;
        GetSizeOnScreen(&size);
        info->ptMinTrackSize.x = size.cx;
        info->ptMinTrackSize.y = size.cy;
      }
      return 0;
    }
    default:
      break;
  }
  return DefSubclassProc(window, message, wparam, lparam);
}

}  // namespace

void configure(unsigned int flags) {
  g_has_custom_frame = (flags & kCustomFrame) != 0;
  g_visible_on_startup = (flags & kHideOnStartup) == 0;
  InstallCreationHook();
}

HWND getAppWindow() { return g_flutter_window; }

void setMinSize(int width, int height) {
  g_min_size.cx = width;
  g_min_size.cy = height;
}

void setWindowCanBeShown(bool value) {
  g_window_can_be_shown = value ? TRUE : FALSE;
}

bool dragAppWindow() {
  if (!g_flutter_window) return false;
  ReleaseCapture();
  SendMessage(g_flutter_window, WM_SYSCOMMAND, SC_MOVE | HTCAPTION, 0);
  return true;
}

}  // namespace waydir_window
