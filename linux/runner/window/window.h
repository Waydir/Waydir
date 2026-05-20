#ifndef WAYDIR_WINDOW_H_
#define WAYDIR_WINDOW_H_

#include <gtk/gtk.h>
#include <flutter_linux/flutter_linux.h>

namespace waydir_window {

constexpr unsigned int kCustomFrame   = 0x1;
constexpr unsigned int kHideOnStartup = 0x2;

// Called from runner after the GtkWindow and FlView are created. Sets up
// borderless frame, mouse-edge hooks for resize, and remembers the window
// handle for later FFI calls.
void init(GtkWindow* window, FlView* view, unsigned int flags);

GtkWindow* getAppWindow();
void startDragging();

}  // namespace waydir_window

#endif  // WAYDIR_WINDOW_H_
