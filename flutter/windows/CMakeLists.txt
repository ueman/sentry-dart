# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

if(FLUTTER_TARGET_PLATFORM EQUAL "windows-arm64")
    set(native_backend "breakpad")
else()
    set(native_backend "crashpad")
endif()

set(SENTRY_BACKEND ${native_backend} CACHE STRING "The sentry backend responsible for reporting crashes" FORCE)

include("${CMAKE_CURRENT_SOURCE_DIR}/../sentry-native/sentry-native.cmake")

# Even though sentry_flutter doesn't actually provide a useful plugin, we need to accommodate the Flutter tooling.
# sentry_flutter/sentry_flutter_plugin.h is included by the flutter-tool generated plugin registrar:
target_include_directories(sentry INTERFACE ${CMAKE_CURRENT_LIST_DIR})
