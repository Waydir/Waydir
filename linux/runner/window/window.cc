// Subset port of bitsdojo_window_linux 0.1.4 (MIT, Copyright 2020-2021 Bogdan
// Hobeanu). See third_party/bitsdojo_window/LICENSE. Stripped of unused
// features (max_size, WindowInfo hash table, debug helpers, screen rect
// queries) and the method-channel/plugin wiring.

#include "window.h"

#include <gdk/gdk.h>

namespace waydir_window {

namespace {

struct State {
  GtkWindow* window = nullptr;
  GtkWidget* event_box = nullptr;
  GdkWindowEdge current_edge = GDK_WINDOW_EDGE_NORTH;
  gboolean is_on_edge = FALSE;
  gboolean is_maximized = FALSE;
  gboolean is_dragging = FALSE;
  gboolean is_resizing = FALSE;
  GdkEventButton current_pressed_event{};
  gulong flutter_button_press_handler = 0;
  gboolean flutter_button_press_blocked = FALSE;
  int width = 0;
  int height = 0;
  int x = 0;
  int y = 0;
  int grip_size = 6;
  int min_width = -1;
  int min_height = -1;
};

State g_state;
gboolean g_visible_on_startup = TRUE;

const gchar* CursorForEdge(GdkWindowEdge edge) {
  switch (edge) {
    case GDK_WINDOW_EDGE_NORTH_WEST: return "nw-resize";
    case GDK_WINDOW_EDGE_NORTH:      return "n-resize";
    case GDK_WINDOW_EDGE_NORTH_EAST: return "ne-resize";
    case GDK_WINDOW_EDGE_EAST:       return "e-resize";
    case GDK_WINDOW_EDGE_SOUTH_EAST: return "se-resize";
    case GDK_WINDOW_EDGE_SOUTH:      return "s-resize";
    case GDK_WINDOW_EDGE_SOUTH_WEST: return "sw-resize";
    case GDK_WINDOW_EDGE_WEST:       return "w-resize";
    default:                         return "default";
  }
}

bool DetectEdge(int width, int height, double x, double y,
                GdkWindowEdge* edge, int margin) {
  if (x < margin) {
    if (y < margin)            *edge = GDK_WINDOW_EDGE_NORTH_WEST;
    else if (y < height - margin) *edge = GDK_WINDOW_EDGE_WEST;
    else                       *edge = GDK_WINDOW_EDGE_SOUTH_WEST;
    return true;
  }
  if (x > width - margin) {
    if (y < margin)            *edge = GDK_WINDOW_EDGE_NORTH_EAST;
    else if (y < height - margin) *edge = GDK_WINDOW_EDGE_EAST;
    else                       *edge = GDK_WINDOW_EDGE_SOUTH_EAST;
    return true;
  }
  if (y < margin)            { *edge = GDK_WINDOW_EDGE_NORTH; return true; }
  if (y >= height - margin)  { *edge = GDK_WINDOW_EDGE_SOUTH; return true; }
  return false;
}

void GetMousePositionOnScreen(GtkWindow* window, gint* x, gint* y) {
  auto screen = gtk_window_get_screen(window);
  auto display = gdk_screen_get_display(screen);
  auto seat = gdk_display_get_default_seat(display);
  auto device = gdk_seat_get_pointer(seat);
  gdk_device_get_position(device, nullptr, x, y);
}

void SetCursor(const gchar* name) {
  GdkWindow* gdw = gtk_widget_get_window(GTK_WIDGET(g_state.window));
  if (!gdw) return;
  GdkCursor* cursor = gdk_cursor_new_from_name(gdk_window_get_display(gdw), name);
  gdk_window_set_cursor(gdw, cursor);
  if (cursor) g_object_unref(cursor);
}

void UpdateMouseCursor() {
  const gchar* name = (g_state.is_on_edge && !g_state.is_maximized)
                          ? CursorForEdge(g_state.current_edge)
                          : "default";
  SetCursor(name);
}

void UpdateEdgeFromPointer(double x, double y) {
  GdkWindowEdge edge = g_state.current_edge;
  bool on_edge = DetectEdge(g_state.width, g_state.height, x, y, &edge,
                            g_state.grip_size);
  gboolean is_max = gtk_window_is_maximized(g_state.window);

  if (edge != g_state.current_edge || on_edge != g_state.is_on_edge ||
      is_max != g_state.is_maximized) {
    g_state.is_maximized = is_max;
    g_state.is_on_edge = on_edge ? TRUE : FALSE;
    g_state.current_edge = edge;
    UpdateMouseCursor();
  }
}

void BlockButtonPress() {
  if (g_state.flutter_button_press_handler == 0) {
    g_state.flutter_button_press_handler = g_signal_handler_find(
        g_state.event_box, G_SIGNAL_MATCH_ID,
        g_signal_lookup("button-press-event", GTK_TYPE_WIDGET), 0, nullptr,
        nullptr, nullptr);
  }
  if (g_state.flutter_button_press_blocked) return;
  g_signal_handler_block(g_state.event_box,
                         g_state.flutter_button_press_handler);
  g_state.flutter_button_press_blocked = TRUE;
}

void UnblockButtonPress() {
  if (!g_state.flutter_button_press_blocked) return;
  g_state.flutter_button_press_blocked = FALSE;
  g_signal_handler_unblock(g_state.event_box,
                           g_state.flutter_button_press_handler);
}

gboolean OnMousePressHook(GSignalInvocationHint*, guint, const GValue* values,
                          gpointer) {
  gpointer instance = g_value_peek_pointer(values);
  if (!GTK_IS_EVENT_BOX(instance)) return TRUE;
  GdkEventButton* event =
      static_cast<GdkEventButton*>(g_value_get_boxed(values + 1));

  if (g_state.is_on_edge && !g_state.is_maximized) {
    BlockButtonPress();
    g_state.is_resizing = TRUE;
    gtk_window_begin_resize_drag(
        g_state.window, g_state.current_edge, event->button,
        static_cast<gint>(event->x_root), static_cast<gint>(event->y_root),
        event->time);
  }
  memset(&g_state.current_pressed_event, 0, sizeof(GdkEventButton));
  memcpy(&g_state.current_pressed_event, event, sizeof(GdkEventButton));
  return TRUE;
}

gboolean OnMouseReleaseHook(GSignalInvocationHint*, guint,
                            const GValue* values, gpointer) {
  gpointer instance = g_value_peek_pointer(values);
  if (!GTK_IS_EVENT_BOX(instance)) return TRUE;
  UnblockButtonPress();
  return TRUE;
}

gboolean OnMouseMoveHook(GSignalInvocationHint*, guint, const GValue* values,
                         gpointer) {
  gpointer instance = g_value_peek_pointer(values);
  if (!GTK_IS_EVENT_BOX(instance)) return TRUE;
  GdkEventMotion* event =
      static_cast<GdkEventMotion*>(g_value_get_boxed(values + 1));
  if (!event) return TRUE;
  UpdateEdgeFromPointer(event->x, event->y);
  return TRUE;
}

void EmitSyntheticMouseMove(GtkWidget* widget, int x, int y) {
  auto event = reinterpret_cast<GdkEventButton*>(gdk_event_new(GDK_MOTION_NOTIFY));
  event->type = GDK_MOTION_NOTIFY;
  event->x = x;
  event->y = y;
  event->time = g_get_monotonic_time();
  gboolean result;
  g_signal_emit_by_name(widget, "motion-notify-event", event, &result);
  gdk_event_free(reinterpret_cast<GdkEvent*>(event));
}

gboolean OnWindowEventAfter(GtkWidget*, GdkEvent* event, gpointer) {
  if (event->type == GDK_ENTER_NOTIFY) {
    if (!g_state.event_box) return FALSE;
    if (g_state.is_dragging) {
      g_state.is_dragging = FALSE;
      auto release =
          reinterpret_cast<GdkEventButton*>(gdk_event_new(GDK_BUTTON_RELEASE));
      release->x = g_state.current_pressed_event.x;
      release->y = g_state.current_pressed_event.y;
      release->button = g_state.current_pressed_event.button;
      release->type = GDK_BUTTON_RELEASE;
      release->time = g_get_monotonic_time();
      gboolean result;
      g_signal_emit_by_name(g_state.event_box, "button-release-event", release,
                            &result);
      gdk_event_free(reinterpret_cast<GdkEvent*>(release));
    }
    if (g_state.is_resizing) g_state.is_resizing = FALSE;
    UnblockButtonPress();
    gint x, y;
    GetMousePositionOnScreen(g_state.window, &x, &y);
    x -= g_state.x;
    y -= g_state.y;
    EmitSyntheticMouseMove(g_state.event_box, x, y);
  } else if (event->type == GDK_LEAVE_NOTIFY) {
    if (g_state.event_box) EmitSyntheticMouseMove(g_state.event_box, -1, -1);
  }
  return FALSE;
}

gboolean OnConfigure(GtkWidget*, GdkEventConfigure* event, gpointer) {
  g_state.x = event->x;
  g_state.y = event->y;
  g_state.width = event->width;
  g_state.height = event->height;
  return FALSE;
}

void FindEventBox(GtkWidget* widget) {
  if (!GTK_IS_CONTAINER(widget)) return;
  GList* children = nullptr;
  gtk_container_forall(GTK_CONTAINER(widget),
                       [](GtkWidget* w, gpointer data) {
                         auto* list = static_cast<GList**>(data);
                         *list = g_list_prepend(*list, w);
                       },
                       &children);
  for (GList* c = children; c; c = c->next) {
    auto* child = GTK_WIDGET(c->data);
    if (GTK_IS_EVENT_BOX(child)) {
      g_state.event_box = child;
      break;
    }
  }
  g_list_free(children);
}

void InstallSignalHooks() {
  g_signal_add_emission_hook(
      g_signal_lookup("motion-notify-event", GTK_TYPE_WIDGET), 0,
      OnMouseMoveHook, nullptr, nullptr);
  g_signal_add_emission_hook(
      g_signal_lookup("button-press-event", GTK_TYPE_WIDGET), 0,
      OnMousePressHook, nullptr, nullptr);
  g_signal_add_emission_hook(
      g_signal_lookup("button-release-event", GTK_TYPE_WIDGET), 0,
      OnMouseReleaseHook, nullptr, nullptr);
}

void SetupCustomFrame(GtkWindow* window) {
  GdkScreen* screen = gtk_window_get_screen(window);
  gtk_window_set_decorated(window, FALSE);
  GdkVisual* rgba = gdk_screen_get_rgba_visual(screen);
  if (rgba && gdk_screen_is_composited(screen)) {
    gtk_widget_set_visual(GTK_WIDGET(window), rgba);
  }
  auto* css = gtk_css_provider_new();
  gtk_css_provider_load_from_data(
      GTK_CSS_PROVIDER(css), "window {\n   background:none;\n}\n", -1, nullptr);
  gtk_style_context_add_provider_for_screen(
      screen, GTK_STYLE_PROVIDER(css), GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);
  g_object_unref(css);
}

}  // namespace

void init(GtkWindow* window, FlView* view, unsigned int flags) {
  g_state.window = window;
  g_visible_on_startup = (flags & kHideOnStartup) == 0;

  if (flags & kCustomFrame) SetupCustomFrame(window);

  g_signal_connect(window, "event-after", G_CALLBACK(OnWindowEventAfter),
                   nullptr);
  g_signal_connect(window, "configure-event", G_CALLBACK(OnConfigure), nullptr);

  FindEventBox(GTK_WIDGET(view));
  if (g_state.event_box) InstallSignalHooks();
}

GtkWindow* getAppWindow() { return g_state.window; }

void startDragging() {
  if (!g_state.window) return;
  gint x, y;
  GetMousePositionOnScreen(g_state.window, &x, &y);
  g_state.is_dragging = TRUE;
  gtk_window_begin_move_drag(g_state.window, 1, x, y,
                             static_cast<guint32>(g_get_monotonic_time()));
}

}  // namespace waydir_window
