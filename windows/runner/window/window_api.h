#ifndef WAYDIR_WINDOW_API_H_
#define WAYDIR_WINDOW_API_H_

#ifdef __cplusplus
extern "C" {
#endif

#define WAYDIR_WINDOW_CUSTOM_FRAME    0x1
#define WAYDIR_WINDOW_HIDE_ON_STARTUP 0x2

__declspec(dllexport) void waydir_window_configure(unsigned int flags);
__declspec(dllexport) void waydir_window_set_min_size(int width, int height);
__declspec(dllexport) void waydir_window_show();
__declspec(dllexport) void waydir_window_hide();
__declspec(dllexport) void waydir_window_minimize();
__declspec(dllexport) void waydir_window_maximize();
__declspec(dllexport) void waydir_window_restore();
__declspec(dllexport) void waydir_window_close();
__declspec(dllexport) int  waydir_window_is_maximized();
__declspec(dllexport) int  waydir_window_is_visible();
__declspec(dllexport) void waydir_window_start_dragging();
__declspec(dllexport) void waydir_window_set_title(const wchar_t* title);
__declspec(dllexport) void waydir_window_set_size(int width, int height);
__declspec(dllexport) void waydir_window_get_size(int* width, int* height);
__declspec(dllexport) void waydir_window_center();

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // WAYDIR_WINDOW_API_H_
