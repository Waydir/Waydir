add_library(waydir_window STATIC
  "window.cpp"
  "window_api.cpp"
)

apply_standard_settings(waydir_window)

set_target_properties(waydir_window PROPERTIES
  CXX_VISIBILITY_PRESET hidden)

target_include_directories(waydir_window PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}")

target_link_libraries(waydir_window PRIVATE dwmapi Comctl32)
