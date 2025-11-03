# AStar 路径规划算法可视化工具

![Qt6](https://img.shields.io/badge/Qt6-Quick-blue)
![C++17](https://img.shields.io/badge/C++17-Modern-green)

## 项目简介
一个基于 Qt6 的 A* 算法可视化教学工具，用于直观演示路径规划算法在二维网格中的工作原理。通过交互式界面帮助学习者理解开放集、关闭集、启发式函数等核心概念。

## 核心功能
- 🗺️ 可视化 A* 算法的完整搜索过程
- ✏️ 交互式设置起点、终点和障碍物
- 🌈 实时高亮显示搜索状态（开放集/关闭集/最终路径）
- ⚙️ 支持动态调整启发式权重参数

## 技术架构
| 组件 | 技术栈 |
|------|--------|
| 前端 | Qt Quick (QML) + Qt6.7.2 |
| 后端 | C++17 |
| 构建系统 | CMake 3.16+ |
| 设计模式 | MVC 架构 + 信号槽机制 |

## 开发环境要求
- CMake ≥ 3.16
- Qt6 SDK（包含 Core 和 Quick 模块）
- C++17 兼容编译器（MSVC/GCC/Clang）

## 构建与运行
```powershell
# 1. 创建构建目录
mkdir build

# 2. 配置项目（Windows示例）
# 注意替换为你的Qt安装路径
cmake -S . -B build -DCMAKE_PREFIX_PATH="C:/Qt/6.7.2/msvc2019_64"

# 3. 编译项目
cmake --build build --config Release

# 4. 运行程序（Windows）
build/Release/AStar.exe
```

## 部署说明
1. 使用 Qt 工具链部署：
```powershell
# 进入构建目录
cd build/Release

# 自动部署依赖库（MSVC示例）
"C:/Qt/6.7.2/msvc2019_64/bin/windeployqt.exe" AStar.exe

# 手动复制QML控件（若需要）
copy -r "C:/Qt/6.7.2/msvc2019_64/qml/QtQuick/Controls" ./qml/QtQuick/
```

2. 重要注意事项：
- 确保 `main.qml` 位于可执行文件同级目录
- MinGW 构建需手动复制 `libgcc_s_seh-1.dll` 和 `libstdc++-6.dll`
- 建议在纯英文路径下运行程序

## 项目结构
```
AStar/
├── main.cpp            # Qt应用入口
├── pathfinder.h/cpp    # A*算法核心实现
├── imports.cmake       # CMake模块配置
└── README.md           # 本文件
```

> 提示：开发调试时建议使用 Qt Creator 打开 CMakeLists.txt 文件