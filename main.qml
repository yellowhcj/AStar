import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import AStar 1.0

Window {
    id: root
    width: 1200
    height: 900
    minimumWidth: 1000
    minimumHeight: 800
    visible: true
    title: "A* Algorithm Visualizer - Drag ★ and ✖, Click to Toggle Walls"

    Pathfinder {
        id: pathfinder
        gridSize: 15
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // 标题和说明
        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                Text {
                    text: "A* Algorithm Visualizer"
                    font.bold: true
                    font.pixelSize: 24
                    color: "#2c3e50"
                }
                
                Text {
                    text: "Compare Dijkstra/BFS, Greedy Best-First, and A* Algorithms"
                    font.pixelSize: 14
                    color: "#7f8c8d"
                }
            }
            
            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                
                Row {
                    spacing: 20
                    Rectangle { width: 20; height: 20; color: "#f39c12"; border.width: 1; border.color: "#000000" }
                    Text { text: "Start"; color: "#2c3e50"; font.pixelSize: 12 }
                    
                    Rectangle { width: 20; height: 20; color: "#e74c3c"; border.width: 1; border.color: "#000000" }
                    Text { text: "End"; color: "#2c3e50"; font.pixelSize: 12 }
                    
                    Rectangle { width: 20; height: 20; color: "#34495e"; border.width: 1; border.color: "#000000" }
                    Text { text: "Wall"; color: "#2c3e50"; font.pixelSize: 12 }
                    
                    Rectangle { width: 20; height: 20; color: "#3498db"; border.width: 1; border.color: "#000000" }
                    Text { text: "Open Set"; color: "#2c3e50"; font.pixelSize: 12 }
                    
                    Rectangle { width: 20; height: 20; color: "#e74c3c"; border.width: 1; border.color: "#000000" }
                    Text { text: "Closed Set"; color: "#2c3e50"; font.pixelSize: 12 }
                    
                    Rectangle { width: 20; height: 20; color: "#27ae60"; border.width: 1; border.color: "#000000" }
                    Text { text: "Path"; color: "#2c3e50"; font.pixelSize: 12 }
                }
            }
        }

        // 三个算法网格
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 20

            // Dijkstra/BFS Grid
            AlgorithmGrid {
                Layout.preferredWidth: (parent.width - 40) / 3
                Layout.fillHeight: true
                algorithmName: "Dijkstra/BFS"
                costType: "G"
                pathfinder: pathfinder
                algorithm: "dijkstra"
                showCost: true
            }

            // Greedy Grid
            AlgorithmGrid {
                Layout.preferredWidth: (parent.width - 40) / 3
                Layout.fillHeight: true
                algorithmName: "Greedy Best-First"
                costType: "H"
                pathfinder: pathfinder
                algorithm: "greedy"
                showCost: true
            }

            // A* Grid
            AlgorithmGrid {
                Layout.preferredWidth: (parent.width - 40) / 3
                Layout.fillHeight: true
                algorithmName: "A*"
                costType: "F"
                pathfinder: pathfinder
                algorithm: "astar"
                showCost: true
            }
        }

        // 进度条区域
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Progress: " + pathfinder.progress + " / " + pathfinder.maxProgress + 
                      " (Step " + pathfinder.progress + " of " + pathfinder.maxProgress + ")"
                font.bold: true
                color: "#2c3e50"
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: 16
            }

            Slider {
                id: progressBar
                Layout.fillWidth: true
                from: 0
                to: pathfinder.maxProgress
                value: pathfinder.progress
                stepSize: 1
                onMoved: {
                    pathfinder.progress = Math.round(value);
                }

                background: Rectangle {
                    x: progressBar.leftPadding
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 8
                    width: progressBar.availableWidth
                    height: implicitHeight
                    radius: 4
                    color: "#bdc3c7"

                    Rectangle {
                        width: progressBar.visualPosition * parent.width
                        height: parent.height
                        color: "#3498db"
                        radius: 4
                    }
                }

                handle: Rectangle {
                    x: progressBar.leftPadding + progressBar.visualPosition * (progressBar.availableWidth - width)
                    y: progressBar.topPadding + progressBar.availableHeight / 2 - height / 2
                    implicitWidth: 24
                    implicitHeight: 24
                    radius: 12
                    color: progressBar.pressed ? "#2980b9" : "#3498db"
                    border.color: "#2c3e50"
                    border.width: 2
                    
                    Text {
                        anchors.centerIn: parent
                        text: pathfinder.progress
                        color: "white"
                        font.bold: true
                        font.pixelSize: 10
                    }
                }
            }
        }

        // 控制按钮
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 25

            ControlButton {
                text: "⏪ Step Back"
                onClicked: pathfinder.stepBackward()
                enabled: pathfinder.progress > 0
                backgroundColor: "#3498db"
            }

            ControlButton {
                id: simulationButton
                text: pathfinder.isRunning ? "⏹ Stop" : "▶ Start Simulation"
                onClicked: {
                    if (pathfinder.isRunning) {
                        pathfinder.stopSimulation();
                    } else {
                        pathfinder.startSimulation();
                    }
                }
                backgroundColor: pathfinder.isRunning ? "#e74c3c" : "#27ae60"
            }

            ControlButton {
                text: "Step Forward ⏩"
                onClicked: pathfinder.stepForward()
                enabled: pathfinder.progress < pathfinder.maxProgress
                backgroundColor: "#3498db"
            }

            ControlButton {
                text: "🔄 Reset"
                onClicked: pathfinder.resetSimulation()
                backgroundColor: "#f39c12"
            }
        }

        // 提示信息
        Text {
            text: "💡 Tip: You can only modify walls and drag start/end points when progress is at 0%"
            font.pixelSize: 12
            color: "#e74c3c"
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
            visible: pathfinder.progress !== 0
        }
    }

    // 算法网格组件
    component AlgorithmGrid: ColumnLayout {
        required property string algorithmName
        required property string costType
        required property Pathfinder pathfinder
        required property string algorithm
        required property bool showCost

        Layout.preferredWidth: parent.width / 3
        Layout.fillHeight: true
        spacing: 8

        Text {
            text: algorithmName + " (Shows " + costType + " cost)"
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            color: "#2c3e50"
            font.pixelSize: 16
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            border.color: "#34495e"
            border.width: 3
            radius: 8
            color: "transparent"

            Grid {
                id: grid
                anchors.fill: parent
                anchors.margins: 4
                rows: pathfinder.gridSize
                columns: pathfinder.gridSize
                property real cellSize: Math.min(width / pathfinder.gridSize, height / pathfinder.gridSize)

                Repeater {
                    model: pathfinder.gridSize * pathfinder.gridSize
                    delegate: Rectangle {
                        width: grid.cellSize
                        height: grid.cellSize
                        border.color: "#7f8c8d"
                        border.width: 1

                        property int cellX: index % pathfinder.gridSize
                        property int cellY: Math.floor(index / pathfinder.gridSize)
                        property var cellData: {
                            var gridData = algorithm === "dijkstra" ? pathfinder.dijkstraGrid :
                                          algorithm === "greedy" ? pathfinder.greedyGrid :
                                          pathfinder.aStarGrid;
                            if (gridData && gridData[cellY] && gridData[cellY][cellX] !== undefined) {
                                return gridData[cellY][cellX];
                            } else {
                                return {isObstacle: false, isOpen: false, isClosed: false, g: 0, h: 0, f: 0};
                            }
                        }

                        color: {
                            if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "#f39c12"; // 橙色起点
                            else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "#e74c3c"; // 红色终点
                            else if (cellData.isObstacle) return "#34495e"; // 深灰色障碍物
                            else if (pathfinder.isInPath(cellX, cellY, algorithm)) return "#27ae60"; // 绿色路径
                            else if (cellData.isClosed) return "#e74c3c"; // 红色已关闭
                            else if (cellData.isOpen) return "#3498db"; // 蓝色开放集合
                            else return "#ecf0f1"; // 浅灰色未探索
                        }

                        // Open set 的边框加粗
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "#f1c40f"
                            border.width: cellData.isOpen ? 3 : 0
                            visible: cellData.isOpen
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: pathfinder.progress === 0
                            onClicked: {
                                if (!(cellX === pathfinder.start.x && cellY === pathfinder.start.y) &&
                                    !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)) {
                                    pathfinder.toggleObstacle(cellX, cellY);
                                }
                            }
                            onPressed: {
                                if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) {
                                    drag.target = startDragHandler;
                                } else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) {
                                    drag.target = endDragHandler;
                                }
                            }
                            
                            onPositionChanged: {
                                if (drag.target && pathfinder.progress === 0) {
                                    var newX = Math.floor(mouseX / grid.cellSize);
                                    var newY = Math.floor(mouseY / grid.cellSize);
                                    
                                    if (newX >= 0 && newX < pathfinder.gridSize && 
                                        newY >= 0 && newY < pathfinder.gridSize) {
                                        
                                        if (drag.target === startDragHandler) {
                                            pathfinder.start = Qt.point(newX, newY);
                                        } else if (drag.target === endDragHandler) {
                                            pathfinder.end = Qt.point(newX, newY);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "★";
                                else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "✖";
                                else if (cellData.isObstacle) return "█";
                                else if (showCost && (cellData.isClosed || cellData.isOpen)) {
                                    if (algorithm === "dijkstra") return cellData.g;
                                    else if (algorithm === "greedy") return cellData.h;
                                    else return cellData.f;
                                } else return "";
                            }
                            font.pixelSize: Math.min(width, height) * 0.35
                            color: (cellX === pathfinder.start.x && cellY === pathfinder.start.y) || 
                                   (cellX === pathfinder.end.x && cellY === pathfinder.end.y) ? 
                                   "white" : "white"
                            font.bold: true
                        }

                        // 拖拽处理器
                        DragHandler {
                            id: startDragHandler
                            target: null
                        }

                        DragHandler {
                            id: endDragHandler
                            target: null
                        }
                    }
                }
            }
        }
    }

    // 控制按钮组件
    component ControlButton: Button {
        required property string backgroundColor
        property alias buttonText: textItem.text
        
        implicitWidth: 140
        implicitHeight: 45
        
        background: Rectangle {
            color: parent.enabled ? backgroundColor : "#bdc3c7"
            radius: 8
            border.color: "#2c3e50"
            border.width: 2
            
            Rectangle {
                anchors.fill: parent
                color: parent.color
                opacity: parent.parent.pressed ? 0.7 : 0
                Behavior on opacity { NumberAnimation { duration: 100 } }
            }
        }
        
        contentItem: Text {
            id: textItem
            text: parent.text
            font.bold: true
            font.pixelSize: 14
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}