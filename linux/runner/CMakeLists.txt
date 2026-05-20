cmake_minimum_required(VERSION 3.13)
project(runner LANGUAGES CXX)

# Define the application target. To change its name, change BINARY_NAME in the
# top-level CMakeLists.txt, not the value here, or `flutter run` will no longer
# work.
#
# Any new source files that you add to the application should be added here.
add_subdirectory("window")

add_executable(${BINARY_NAME}
  "main.cc"
  "my_application.cc"
  "system_scale.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add preprocessor definitions for the application ID.
add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}")

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE PkgConfig::GTK)
# Force all symbols from waydir_window into the exe (needed for Dart FFI runtime lookup).
target_link_libraries(${BINARY_NAME} PRIVATE
  -Wl,--whole-archive waydir_window -Wl,--no-whole-archive)

target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")

# Export symbols to dynamic symbol table for Dart FFI DynamicLibrary.process()
set_target_properties(${BINARY_NAME} PROPERTIES ENABLE_EXPORTS TRUE)
