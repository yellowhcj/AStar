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

# 添加应用程序图标（Windows平台）
if(WIN32)
    # 方法1：使用RC文件（推荐）
    set(APP_ICON_RC ${CMAKE_CURRENT_SOURCE_DIR}/app_icon.rc)
    
    qt_add_executable(astar_visualizer
        WIN32
        main.cpp
        pathfinder.h
        pathfinder.cpp
        resources.qrc
        main.qml
        ${APP_ICON_RC}  # 添加RC文件
    )
else()
    qt_add_executable(astar_visualizer
        WIN32
        main.cpp
        pathfinder.h
        pathfinder.cpp
        resources.qrc
        main.qml
    )
endif()

target_link_libraries(astar_visualizer PRIVATE Qt6::Core Qt6::Quick Qt6::QuickControls2)

# 设置应用程序图标属性（可选）
set_target_properties(astar_visualizer PROPERTIES
    WIN32_EXECUTABLE TRUE
    MACOSX_BUNDLE_ICON_FILE logo.icns  # 如果是macOS
)