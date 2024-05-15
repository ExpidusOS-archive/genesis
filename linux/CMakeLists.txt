# Project-level configuration.
cmake_minimum_required(VERSION 3.10)
project(runner LANGUAGES CXX C)

# The name of the executable created for the application. Change this to change
# the on-disk name of your application.
set(BINARY_NAME "genesis_shell")
# The unique GTK application identifier for this application. See:
# https://wiki.gnome.org/HowDoI/ChooseApplicationID
set(APPLICATION_ID "com.expidusos.shell")

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(SET CMP0063 NEW)

# Load bundled libraries from the lib/ directory relative to the binary.
set(CMAKE_INSTALL_RPATH "$ORIGIN/lib")

# Root filesystem for cross-building.
if(FLUTTER_TARGET_PLATFORM_SYSROOT)
  set(CMAKE_SYSROOT ${FLUTTER_TARGET_PLATFORM_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
  set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
  set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
  set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
endif()

# Define build configuration options.
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  set(CMAKE_BUILD_TYPE "Debug" CACHE
    STRING "Flutter build mode" FORCE)
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS
    "Debug" "Profile" "Release")
endif()

# Compilation settings that should be applied to most targets.
#
# Be cautious about adding new options here, as plugins use this function by
# default. In most cases, you should add new options to specific targets instead
# of modifying this function.
function(APPLY_STANDARD_SETTINGS TARGET)
  target_compile_features(${TARGET} PUBLIC cxx_std_14)
  target_compile_options(${TARGET} PRIVATE -Wall -Werror)
  target_compile_options(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:-O3>")
  target_compile_definitions(${TARGET} PRIVATE "$<$<NOT:$<CONFIG:Debug>>:NDEBUG>")
endfunction()

# Flutter library and tool build rules.
set(FLUTTER_MANAGED_DIR "${CMAKE_CURRENT_SOURCE_DIR}/flutter")
add_subdirectory(${FLUTTER_MANAGED_DIR})

# System-level dependencies.
set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

find_program(WAYLAND_SCANNER_EXECUTABLE REQUIRED NAMES wayland-scanner)
pkg_get_variable(WAYLAND_PROTOS_DIR wayland-protocols pkgdatadir)

function(WAYLAND_ADD_PROTOCOL_CLIENT _sources _protocol _basename)
  get_filename_component(_infile ${_protocol} ABSOLUTE)
  set(_client_header "${CMAKE_CURRENT_BINARY_DIR}/${_basename}-protocol.h")
  set(_code "${CMAKE_CURRENT_BINARY_DIR}/${_basename}-protocol.c")

  add_custom_command(OUTPUT "${_client_header}"
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} client-header < ${_infile} > ${_client_header}
    DEPENDS ${_infile} VERBATIM)

  #add_custom_command(OUTPUT "${_code}"
  #  COMMAND ${WAYLAND_SCANNER_EXECUTABLE} public-code < ${_infile} > ${_code}
  #  DEPENDS ${_infile} VERBATIM)

  list(APPEND ${_sources} "${_client_header}")
  # "${_code}")
  set(${_sources} ${${_sources}} PARENT_SCOPE)
endfunction()

function(WAYLAND_ADD_PROTOCOL_SERVER _sources _protocol _basename)
  get_filename_component(_infile ${_protocol} ABSOLUTE)
  set(_server_header "${CMAKE_CURRENT_BINARY_DIR}/${_basename}-protocol.h")
  set(_code "${CMAKE_CURRENT_BINARY_DIR}/${_basename}-protocol.c")

  add_custom_command(OUTPUT "${_server_header}"
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} server-header < ${_infile} > ${_server_header}
    DEPENDS ${_infile} VERBATIM)

  add_custom_command(OUTPUT "${_code}"
    COMMAND ${WAYLAND_SCANNER_EXECUTABLE} private-code < ${_infile} > ${_code}
    DEPENDS ${_infile} VERBATIM)

  list(APPEND ${_sources} "${_server_header}" "${_code}")
  set(${_sources} ${${_sources}} PARENT_SCOPE)
endfunction()

find_package(PkgConfig REQUIRED)
pkg_check_modules(ACCOUNTSSERVICE REQUIRED IMPORTED_TARGET accountsservice)
pkg_check_modules(GTK REQUIRED IMPORTED_TARGET gtk+-3.0 epoxy egl)
pkg_check_modules(LIBSEAT REQUIRED IMPORTED_TARGET libseat)
pkg_check_modules(PAM REQUIRED IMPORTED_TARGET pam)
pkg_check_modules(WLROOTS REQUIRED IMPORTED_TARGET wlroots wayland-server wayland-client xkbcommon libdrm)

wayland_add_protocol_client(proto-client-linux-dmabuf-v1 "${WAYLAND_PROTOS_DIR}/unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml" linux-dmabuf-v1-client)
wayland_add_protocol_server(proto-server-linux-dmabuf-v1 "${WAYLAND_PROTOS_DIR}/unstable/linux-dmabuf/linux-dmabuf-unstable-v1.xml" linux-dmabuf-v1-server)

wayland_add_protocol_server(proto-server-xdg-shell "${WAYLAND_PROTOS_DIR}/stable/xdg-shell/xdg-shell.xml" xdg-shell)

include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_definitions(-DAPPLICATION_ID="${APPLICATION_ID}" -DWLR_USE_UNSTABLE)

# Define the application target. To change its name, change BINARY_NAME above,
# not the value here, or `flutter run` will no longer work.
#
# Any new source files that you add to the application should be added here.
add_executable(${BINARY_NAME}
  "main.cc"
  "application.cc"
  "messaging.c"
  "channels/account.cc"
  "channels/applications.cc"
  "channels/auth.cc"
  "channels/display/backend/dummy.c"
  "channels/display/backend/wayland.c"
  "channels/display/backend.c"
  "channels/display/pixel-format.c"
  "channels/display/texture.c"
  "channels/display/surface.c"
  "channels/display.c"
  "channels/outputs.cc"
  "channels/session.cc"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  ${proto-client-linux-dmabuf-v1}
  ${proto-server-linux-dmabuf-v1}
  ${proto-server-xdg-shell}
)

# Apply the standard set of build settings. This can be removed for applications
# that need different build settings.
apply_standard_settings(${BINARY_NAME})

# Add dependency libraries. Add any application-specific dependencies here.
target_link_libraries(${BINARY_NAME} PRIVATE flutter)
target_link_libraries(${BINARY_NAME} PRIVATE
  PkgConfig::ACCOUNTSSERVICE
  PkgConfig::GTK
  PkgConfig::LIBSEAT
  PkgConfig::PAM
  PkgConfig::WLROOTS
  Threads::Threads
)

# Run the Flutter tool portions of the build. This must not be removed.
add_dependencies(${BINARY_NAME} flutter_assemble)

# Only the install-generated bundle's copy of the executable will launch
# correctly, since the resources must in the right relative locations. To avoid
# people trying to run the unbundled copy, put it in a subdirectory instead of
# the default top-level location.
set_target_properties(${BINARY_NAME}
  PROPERTIES
  RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/intermediates_do_not_run"
)


# Generated plugin build rules, which manage building the plugins and adding
# them to the application.
include(flutter/generated_plugins.cmake)


# === Installation ===
# By default, "installing" just makes a relocatable bundle in the build
# directory.
set(BUILD_BUNDLE_DIR "${PROJECT_BINARY_DIR}/bundle")
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${BUILD_BUNDLE_DIR}" CACHE PATH "..." FORCE)
endif()

# Start with a clean build bundle directory every time.
install(CODE "
  file(REMOVE_RECURSE \"${BUILD_BUNDLE_DIR}/\")
  " COMPONENT Runtime)

set(INSTALL_BUNDLE_DATA_DIR "${CMAKE_INSTALL_PREFIX}/data")
set(INSTALL_BUNDLE_LIB_DIR "${CMAKE_INSTALL_PREFIX}/lib")

install(TARGETS ${BINARY_NAME} RUNTIME DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_ICU_DATA_FILE}" DESTINATION "${INSTALL_BUNDLE_DATA_DIR}"
  COMPONENT Runtime)

install(FILES "${FLUTTER_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
  COMPONENT Runtime)

install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/data/pam" DESTINATION "${CMAKE_INSTALL_PREFIX}/etc/pam.d"
  RENAME "genesis-shell")

foreach(bundled_library ${PLUGIN_BUNDLED_LIBRARIES})
  install(FILES "${bundled_library}"
    DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endforeach(bundled_library)

# Copy the native assets provided by the build.dart from all packages.
set(NATIVE_ASSETS_DIR "${PROJECT_BUILD_DIR}native_assets/linux/")
install(DIRECTORY "${NATIVE_ASSETS_DIR}"
   DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
   COMPONENT Runtime)

# Fully re-copy the assets directory on each build to avoid having stale files
# from a previous install.
set(FLUTTER_ASSET_DIR_NAME "flutter_assets")
install(CODE "
  file(REMOVE_RECURSE \"${INSTALL_BUNDLE_DATA_DIR}/${FLUTTER_ASSET_DIR_NAME}\")
  " COMPONENT Runtime)
install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"
  DESTINATION "${INSTALL_BUNDLE_DATA_DIR}" COMPONENT Runtime)

# Install the AOT library on non-Debug builds only.
if(NOT CMAKE_BUILD_TYPE MATCHES "Debug")
  install(FILES "${AOT_LIBRARY}" DESTINATION "${INSTALL_BUNDLE_LIB_DIR}"
    COMPONENT Runtime)
endif()
