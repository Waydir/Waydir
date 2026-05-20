#ifndef WAYDIR_WINDOW_H_
#define WAYDIR_WINDOW_H_

#include <windows.h>

namespace waydir_window {

// Flags for configure().
constexpr unsigned int kCustomFrame    = 0x1;
constexpr unsigned int kHideOnStartup  = 0x2;

void configure(unsigned int flags);
HWND getAppWindow();

void setMinSize(int width, int height);
void setWindowCanBeShown(bool value);
bool dragAppWindow();

}  // namespace waydir_window

#endif  // WAYDIR_WINDOW_H_
