#include "window_api.h"

#include <windows.h>

#include "window.h"

extern "C" {

void waydir_window_configure(unsigned int flags) {
  waydir_window::configure(flags);
}

void waydir_window_set_min_size(int width, int height) {
  waydir_window::setMinSize(width, height);
}

void waydir_window_show() {
  HWND hwnd = waydir_window::getAppWindow();
  if (!hwnd) return;
  waydir_window::setWindowCanBeShown(true);
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOSIZE | SWP_NOMOVE | SWP_SHOWWINDOW);
}

void waydir_window_hide() {
  HWND hwnd = waydir_window::getAppWindow();
  if (!hwnd) return;
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOSIZE | SWP_NOMOVE | SWP_HIDEWINDOW);
}

void waydir_window_minimize() {
  HWND hwnd = waydir_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_MINIMIZE, 0);
}

void waydir_window_maximize() {
  HWND hwnd = waydir_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_MAXIMIZE, 0);
}

void waydir_window_restore() {
  HWND hwnd = waydir_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_RESTORE, 0);
}

void waydir_window_close() {
  HWND hwnd = waydir_window::getAppWindow();
  if (hwnd) PostMessage(hwnd, WM_SYSCOMMAND, SC_CLOSE, 0);
}

int waydir_window_is_maximized() {
  HWND hwnd = waydir_window::getAppWindow();
  return (hwnd && IsZoomed(hwnd)) ? 1 : 0;
}

int waydir_window_is_visible() {
  HWND hwnd = waydir_window::getAppWindow();
  return (hwnd && IsWindowVisible(hwnd)) ? 1 : 0;
}

void waydir_window_start_dragging() { waydir_window::dragAppWindow(); }

void waydir_window_set_title(const wchar_t* title) {
  HWND hwnd = waydir_window::getAppWindow();
  if (hwnd && title) SetWindowTextW(hwnd, title);
}

void waydir_window_set_size(int width, int height) {
  HWND hwnd = waydir_window::getAppWindow();
  if (!hwnd) return;
  UINT dpi = GetDpiForWindow(hwnd);
  double scale = dpi / 96.0;
  int w = static_cast<int>(width * scale);
  int h = static_cast<int>(height * scale);
  SetWindowPos(hwnd, nullptr, 0, 0, w, h, SWP_NOMOVE | SWP_NOZORDER);
}

void waydir_window_get_size(int* width, int* height) {
  HWND hwnd = waydir_window::getAppWindow();
  if (!hwnd || !width || !height) return;
  RECT rc;
  GetWindowRect(hwnd, &rc);
  UINT dpi = GetDpiForWindow(hwnd);
  double scale = dpi / 96.0;
  *width = static_cast<int>((rc.right - rc.left) / scale);
  *height = static_cast<int>((rc.bottom - rc.top) / scale);
}

void waydir_window_center() {
  HWND hwnd = waydir_window::getAppWindow();
  if (!hwnd) return;
  RECT rc;
  GetWindowRect(hwnd, &rc);
  int w = rc.right - rc.left;
  int h = rc.bottom - rc.top;
  HMONITOR mon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
  MONITORINFO info = {};
  info.cbSize = sizeof(MONITORINFO);
  if (!GetMonitorInfoW(mon, &info)) return;
  int mw = info.rcWork.right - info.rcWork.left;
  int mh = info.rcWork.bottom - info.rcWork.top;
  int x = info.rcWork.left + (mw - w) / 2;
  int y = info.rcWork.top + (mh - h) / 2;
  SetWindowPos(hwnd, nullptr, x, y, 0, 0,
               SWP_NOZORDER | SWP_NOACTIVATE | SWP_NOSIZE);
}

}  // extern "C"
