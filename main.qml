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
    title: "Pathfinding Algorithms Visualizer"

    Pathfinder {
        id: pathfinder
        gridSize: 15
        
        onGridChanged: {
            console.log("Grid changed, progress:", progress)
            // 强制刷新所有网格
            dijkstraGridRepeater.model = 0
            dijkstraGridRepeater.model = pathfinder.gridSize * pathfinder.gridSize
            greedyGridRepeater.model = 0  
            greedyGridRepeater.model = pathfinder.gridSize * pathfinder.gridSize
            aStarGridRepeater.model = 0
            aStarGridRepeater.model = pathfinder.gridSize * pathfinder.gridSize
        }
        
        onProgressChanged: {
            console.log("Progress changed to:", progress)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            
            ColumnLayout {
                Text {
                    text: "Pathfinding Algorithms Visualizer"
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
            
            RowLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 15
                
                ColumnLayout {
                    Layout.alignment: Qt.AlignRight
                    
                    Grid {
                        columns: 3
                        spacing: 10
                        
                        LegendItem { color: "#f39c12"; text: "Start" }
                        LegendItem { color: "#e74c3c"; text: "End" }
                        LegendItem { color: "#34495e"; text: "Wall" }
                        
                        LegendItem { color: "#3498db"; text: "Open Set" }
                        LegendItem { color: "#9b59b6"; text: "Closed Set" }
                        LegendItem { color: "#27ae60"; text: "Path" }
                    }
                }
                
                Button {
                    text: "🔧 Debug"
                    font.pixelSize: 16
                    implicitWidth: 80
                    implicitHeight: 40
                    
                    background: Rectangle {
                        color: parent.pressed ? "#95a5a6" : "#bdc3c7"
                        radius: 5
                        border.color: "#7f8c8d"
                        border.width: 1
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: "#2c3e50"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        console.log("=== DEBUG BUTTON CLICKED ===")
                        pathfinder.debugPrintGrids()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            ColumnLayout {
                Layout.preferredWidth: (parent.width - 20) / 3
                Layout.fillHeight: true
                spacing: 5

                Text {
                    text: "Dijkstra/BFS (G cost)"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: "#34495e"
                    border.width: 2
                    radius: 5
                    color: "transparent"

                    Item {
                        id: dijkstraGridContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 20
                        height: width

                        Grid {
                            id: dijkstraGrid
                            anchors.fill: parent
                            rows: pathfinder.gridSize
                            columns: pathfinder.gridSize
                            property real cellSize: width / pathfinder.gridSize

                            Repeater {
                                id: dijkstraGridRepeater
                                model: pathfinder.gridSize * pathfinder.gridSize
                                
                                // Dijkstra 网格 delegate - 使用直接函数调用
                                delegate: Rectangle {
                                    id: dijkstraCell
                                    width: dijkstraGrid.cellSize
                                    height: dijkstraGrid.cellSize
                                    border.color: "#7f8c8d"
                                    border.width: 0.5

                                    property int cellX: index % pathfinder.gridSize
                                    property int cellY: Math.floor(index / pathfinder.gridSize)
                                    
                                    // 使用直接函数调用获取数据
                                    property var cellData: pathfinder.getDijkstraCell(cellX, cellY)

                                    color: {
                                        // 调试输出：检查关键单元格的数据
                                        if (cellX === 0 && cellY === 0) {
                                            console.log("Dijkstra (0,0):", "open=" + cellData.isOpen, "closed=" + cellData.isClosed, "path=" + cellData.isPath)
                                        }
                                        if (cellX === 1 && cellY === 0) {
                                            console.log("Dijkstra (1,0):", "open=" + cellData.isOpen, "closed=" + cellData.isClosed, "path=" + cellData.isPath)
                                        }
                                        
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "#f39c12";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "#e74c3c";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: pathfinder.progress === 0
                                        onClicked: {
                                            console.log("Cell clicked: (" + cellX + "," + cellY + ")")
                                            if (!(cellX === pathfinder.start.x && cellY === pathfinder.start.y) &&
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)) {
                                                console.log("Toggling obstacle at: (" + cellX + "," + cellY + ")")
                                                pathfinder.toggleObstacle(cellX, cellY);
                                            }
                                        }
                                        onPressed: {
                                            if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) {
                                                drag.target = dijkstraStartDrag;
                                            } else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) {
                                                drag.target = dijkstraEndDrag;
                                            }
                                        }
                                    }

                                    Item {
                                        id: dijkstraStartDrag
                                        x: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        y: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        width: dijkstraCell.width
                                        height: dijkstraCell.height
                                        
                                        Drag.active: dijkstraStartDrag.Drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            var point = dijkstraCell.mapToItem(dijkstraGrid, dijkstraStartDrag.x + width/2, dijkstraStartDrag.y + height/2);
                                            var newX = Math.floor(point.x / dijkstraGrid.cellSize);
                                            var newY = Math.floor(point.y / dijkstraGrid.cellSize);
                                            
                                            if (newX >= 0 && newX < pathfinder.gridSize && 
                                                newY >= 0 && newY < pathfinder.gridSize &&
                                                !(newX === pathfinder.end.x && newY === pathfinder.end.y)) {
                                                pathfinder.start = Qt.point(newX, newY);
                                            }
                                        }
                                    }

                                    Item {
                                        id: dijkstraEndDrag
                                        x: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        y: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        width: dijkstraCell.width
                                        height: dijkstraCell.height
                                        
                                        Drag.active: dijkstraEndDrag.Drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            var point = dijkstraCell.mapToItem(dijkstraGrid, dijkstraEndDrag.x + width/2, dijkstraEndDrag.y + height/2);
                                            var newX = Math.floor(point.x / dijkstraGrid.cellSize);
                                            var newY = Math.floor(point.y / dijkstraGrid.cellSize);
                                            
                                            if (newX >= 0 && newX < pathfinder.gridSize && 
                                                newY >= 0 && newY < pathfinder.gridSize &&
                                                !(newX === pathfinder.start.x && newY === pathfinder.start.y)) {
                                                pathfinder.end = Qt.point(newX, newY);
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "★";
                                            else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "✖";
                                            else if (cellData.isObstacle) return "█";
                                            else if (cellData.isOpen || cellData.isClosed) {
                                                return cellData.g > 0 && cellData.g < 999 ? cellData.g : "";
                                            }
                                            return "";
                                        }
                                        font.pixelSize: Math.min(dijkstraCell.width, dijkstraCell.height) * 0.4
                                        color: "white"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: (parent.width - 20) / 3
                Layout.fillHeight: true
                spacing: 5

                Text {
                    text: "Greedy Best-First (H cost)"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: "#34495e"
                    border.width: 2
                    radius: 5
                    color: "transparent"

                    Item {
                        id: greedyGridContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 20
                        height: width

                        Grid {
                            id: greedyGrid
                            anchors.fill: parent
                            rows: pathfinder.gridSize
                            columns: pathfinder.gridSize
                            property real cellSize: width / pathfinder.gridSize

                            Repeater {
                                id: greedyGridRepeater
                                model: pathfinder.gridSize * pathfinder.gridSize
                                
                                // Greedy 网格 delegate - 使用直接函数调用
                                delegate: Rectangle {
                                    id: greedyCell
                                    width: greedyGrid.cellSize
                                    height: greedyGrid.cellSize
                                    border.color: "#7f8c8d"
                                    border.width: 0.5

                                    property int cellX: index % pathfinder.gridSize
                                    property int cellY: Math.floor(index / pathfinder.gridSize)
                                    
                                    property var cellData: pathfinder.getGreedyCell(cellX, cellY)

                                    color: {
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "#f39c12";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "#e74c3c";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "★";
                                            else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "✖";
                                            else if (cellData.isObstacle) return "█";
                                            else if (cellData.isOpen || cellData.isClosed) {
                                                return cellData.h > 0 ? cellData.h : "";
                                            }
                                            return "";
                                        }
                                        font.pixelSize: Math.min(greedyCell.width, greedyCell.height) * 0.4
                                        color: "white"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.preferredWidth: (parent.width - 20) / 3
                Layout.fillHeight: true
                spacing: 5

                Text {
                    text: "A* (F cost)"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    color: "#2c3e50"
                    font.pixelSize: 14
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    border.color: "#34495e"
                    border.width: 2
                    radius: 5
                    color: "transparent"

                    Item {
                        id: aStarGridContainer
                        anchors.centerIn: parent
                        width: Math.min(parent.width, parent.height) - 20
                        height: width

                        Grid {
                            id: aStarGrid
                            anchors.fill: parent
                            rows: pathfinder.gridSize
                            columns: pathfinder.gridSize
                            property real cellSize: width / pathfinder.gridSize

                            Repeater {
                                id: aStarGridRepeater
                                model: pathfinder.gridSize * pathfinder.gridSize
                                
                                // A* 网格 delegate - 使用直接函数调用
                                delegate: Rectangle {
                                    id: aStarCell
                                    width: aStarGrid.cellSize
                                    height: aStarGrid.cellSize
                                    border.color: "#7f8c8d"
                                    border.width: 0.5

                                    property int cellX: index % pathfinder.gridSize
                                    property int cellY: Math.floor(index / pathfinder.gridSize)
                                    
                                    property var cellData: pathfinder.getAStarCell(cellX, cellY)

                                    color: {
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "#f39c12";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "#e74c3c";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "★";
                                            else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "✖";
                                            else if (cellData.isObstacle) return "█";
                                            else if (cellData.isOpen || cellData.isClosed) {
                                                return cellData.f > 0 && cellData.f < 999 ? cellData.f : "";
                                            }
                                            return "";
                                        }
                                        font.pixelSize: Math.min(aStarCell.width, aStarCell.height) * 0.4
                                        color: "white"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: `Step ${pathfinder.progress} of ${pathfinder.maxProgress}`
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
                snapMode: Slider.SnapAlways
                
                onMoved: {
                    pathfinder.progress = value
                }

                background: Rectangle {
                    implicitHeight: 8
                    color: "#bdc3c7"
                    radius: 4

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
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 15

            ControlButton {
                text: "⏪ Step Back"
                onClicked: pathfinder.stepBackward()
                enabled: pathfinder.progress > 0
                backgroundColor: "#3498db"
            }

            ControlButton {
                text: pathfinder.isRunning ? "⏹ Stop" : "▶ Start"
                onClicked: pathfinder.isRunning ? pathfinder.stopSimulation() : pathfinder.startSimulation()
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

        Text {
            text: pathfinder.progress === 0 ? 
                  "💡 Click to toggle walls • Drag ★ and ✖ to move start/end points" :
                  "💡 Reset to step 0 to modify the map"
            font.pixelSize: 12
            color: pathfinder.progress === 0 ? "#27ae60" : "#e74c3c"
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }

    component LegendItem: RowLayout {
        required property color color
        required property string text
        
        spacing: 5
        
        Rectangle {
            width: 16
            height: 16
            color: parent.color
            border.width: 1
            border.color: "#000000"
        }
        
        Text {
            text: parent.text
            color: "#2c3e50"
            font.pixelSize: 12
        }
    }

    component ControlButton: Button {
        required property string backgroundColor
        
        implicitWidth: 140
        implicitHeight: 40
        
        background: Rectangle {
            color: parent.enabled ? backgroundColor : "#bdc3c7"
            radius: 8
            border.color: "#2c3e50"
            border.width: 2
        }
        
        contentItem: Text {
            text: parent.text
            font.bold: true
            font.pixelSize: 14
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }
}