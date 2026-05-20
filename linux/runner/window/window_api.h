#ifndef WAYDIR_WINDOW_API_H_
#define WAYDIR_WINDOW_API_H_

#define WAYDIR_VISIBLE __attribute__((visibility("default")))

#ifdef __cplusplus
extern "C" {
#endif

#define WAYDIR_WINDOW_CUSTOM_FRAME    0x1
#define WAYDIR_WINDOW_HIDE_ON_STARTUP 0x2

WAYDIR_VISIBLE void waydir_window_set_min_size(int width, int height);
WAYDIR_VISIBLE void waydir_window_show();
WAYDIR_VISIBLE void waydir_window_hide();
WAYDIR_VISIBLE void waydir_window_minimize();
WAYDIR_VISIBLE void waydir_window_maximize();
WAYDIR_VISIBLE void waydir_window_restore();
WAYDIR_VISIBLE void waydir_window_close();
WAYDIR_VISIBLE int  waydir_window_is_maximized();
WAYDIR_VISIBLE int  waydir_window_is_visible();
WAYDIR_VISIBLE void waydir_window_start_dragging();
WAYDIR_VISIBLE void waydir_window_set_title(const char* title);
WAYDIR_VISIBLE void waydir_window_set_size(int width, int height);
WAYDIR_VISIBLE void waydir_window_get_size(int* width, int* height);
WAYDIR_VISIBLE void waydir_window_center();

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // WAYDIR_WINDOW_API_H_
