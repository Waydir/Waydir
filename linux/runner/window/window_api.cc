#include "window_api.h"

#include <gtk/gtk.h>

#include "window.h"

extern "C" {

void waydir_window_set_min_size(int width, int height) {
  auto* window = waydir_window::getAppWindow();
  if (!window) return;
  GdkGeometry geom = {};
  geom.min_width = width;
  geom.min_height = height;
  gtk_window_set_geometry_hints(window, nullptr, &geom, GDK_HINT_MIN_SIZE);
}

void waydir_window_show() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_widget_show_all(GTK_WIDGET(window));
}

void waydir_window_hide() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_widget_hide(GTK_WIDGET(window));
}

void waydir_window_minimize() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_window_iconify(window);
}

void waydir_window_maximize() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_window_maximize(window);
}

void waydir_window_restore() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_window_unmaximize(window);
}

void waydir_window_close() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_window_close(window);
}

int waydir_window_is_maximized() {
  auto* window = waydir_window::getAppWindow();
  return (window && gtk_window_is_maximized(window)) ? 1 : 0;
}

int waydir_window_is_visible() {
  auto* window = waydir_window::getAppWindow();
  return (window && gtk_widget_get_visible(GTK_WIDGET(window))) ? 1 : 0;
}

void waydir_window_start_dragging() { waydir_window::startDragging(); }

void waydir_window_set_title(const char* title) {
  auto* window = waydir_window::getAppWindow();
  if (window && title) gtk_window_set_title(window, title);
}

void waydir_window_set_size(int width, int height) {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_window_resize(window, width, height);
}

void waydir_window_get_size(int* width, int* height) {
  auto* window = waydir_window::getAppWindow();
  if (!window || !width || !height) return;
  gtk_window_get_size(window, width, height);
}

void waydir_window_center() {
  auto* window = waydir_window::getAppWindow();
  if (window) gtk_window_set_position(window, GTK_WIN_POS_CENTER);
}

}  // extern "C"
