cmake_minimum_required(VERSION 3.22)
project(logzig)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

##########################################################################################
# Raylib
##########################################################################################

include(FetchContent)
set(FETCHCONTENT_QUIET FALSE)
set(BUILD_SHARED_LIBS ON  CACHE BOOL "" FORCE) # enable shared library
set(BUILD_EXAMPLES    OFF CACHE BOOL "" FORCE) # don't build the supplied examples
set(BUILD_GAMES       OFF CACHE BOOL "" FORCE) # don't build the supplied example games

FetchContent_Declare(
    raylib
    GIT_REPOSITORY "https://github.com/raysan5/raylib.git"
    GIT_TAG "5.0"
    GIT_PROGRESS TRUE
    GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(raylib)

##########################################################################################
# Project executable setup
##########################################################################################

add_executable(logzig 
    src/main.cpp
)

add_library(game SHARED
    src/game/game.cpp
    src/game/game.h
    src/game/export.h
)

target_link_libraries(game PRIVATE raylib)
target_link_libraries(logzig PRIVATE raylib)
