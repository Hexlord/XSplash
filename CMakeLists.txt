cmake_minimum_required(VERSION 3.8)
cmake_policy(SET CMP0026 OLD)
project(XSplash CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
enable_language(C CXX ASM)
include(FindPkgConfig)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/CMake")
find_package(PkgConfig)
find_package(Threads REQUIRED)
find_package(SDL2 REQUIRED)
find_package(SDL2_image REQUIRED)
find_package(Cairo REQUIRED)
find_package(X11 REQUIRED)
find_package(GIF REQUIRED)

add_executable( XSplash Source/main.cpp)
target_include_directories( XSplash PUBLIC Source )
target_link_libraries (XSplash PUBLIC SDL2 SDL2_image X11 Xfixes cairo gif )

set_target_properties(XSplash PROPERTIES RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}")
