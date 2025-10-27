cmake_minimum_required(VERSION 3.16)
project(astar_visualizer)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# 添加MSVC编码和C++17支持选项
if(MSVC)
    add_compile_options(/utf-8 /Zc:__cplusplus /permissive-)
endif()

find_package(Qt6 COMPONENTS Core Quick QuickControls2 REQUIRED)

qt_add_executable(astar_visualizer
    WIN32
    main.cpp
    pathfinder.h
    pathfinder.cpp
    resources.qrc
    main.qml
)

target_link_libraries(astar_visualizer PRIVATE Qt6::Core Qt6::Quick Qt6::QuickControls2)