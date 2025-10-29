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
                
                // 添加交互调试按钮
                Button {
                    text: "🗺️ Map Debug"
                    font.pixelSize: 16
                    implicitWidth: 100
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
                        console.log("=== MAP DEBUG BUTTON CLICKED ===")
                        console.log("Current progress:", pathfinder.progress)
                        console.log("Start position: (" + pathfinder.start.x + "," + pathfinder.start.y + ")")
                        console.log("End position: (" + pathfinder.end.x + "," + pathfinder.end.y + ")")
                        console.log("Grid size:", pathfinder.gridSize)
                        console.log("Max progress:", pathfinder.maxProgress)
                    }
                }
                
                Button {
                    text: "🔧 Algo Debug"
                    font.pixelSize: 16
                    implicitWidth: 100
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
                        console.log("=== ALGORITHM DEBUG BUTTON CLICKED ===")
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
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "#f39c12";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "#e74c3c";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isFinalPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    // 修复：确保鼠标交互正常工作
                                    MouseArea {
                                        id: dijkstraMouseArea
                                        anchors.fill: parent
                                        enabled: pathfinder.progress === 0
                                        hoverEnabled: true
                                        
                                        onEntered: {
                                            if (pathfinder.progress === 0) {
                                                dijkstraCell.border.width = 2
                                                dijkstraCell.border.color = "#e74c3c"
                                            }
                                        }
                                        
                                        onExited: {
                                            dijkstraCell.border.width = 0.5
                                            dijkstraCell.border.color = "#7f8c8d"
                                        }
                                        
                                        onClicked: {
                                            console.log("=== DIJKSTRA CELL CLICKED ===")
                                            console.log("Cell coordinates: (" + cellX + "," + cellY + ")")
                                            console.log("Current progress: " + pathfinder.progress)
                                            console.log("Start position: (" + pathfinder.start.x + "," + pathfinder.start.y + ")")
                                            console.log("End position: (" + pathfinder.end.x + "," + pathfinder.end.y + ")")
                                            
                                            if (!(cellX === pathfinder.start.x && cellY === pathfinder.start.y) &&
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)) {
                                                console.log("Calling toggleObstacle...")
                                                pathfinder.toggleObstacle(cellX, cellY);
                                            } else {
                                                console.log("Cell is start or end position, skipping toggle")
                                            }
                                        }
                                        
                                        onPressed: {
                                            console.log("Mouse pressed on cell (" + cellX + "," + cellY + ")")
                                            if (pathfinder.progress === 0) {
                                                if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) {
                                                    console.log("Starting start drag...")
                                                    drag.target = dijkstraStartDrag;
                                                } else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) {
                                                    console.log("Starting end drag...")
                                                    drag.target = dijkstraEndDrag;
                                                }
                                            }
                                        }
                                    }

                                    // 起点拖动
                                    Item {
                                        id: dijkstraStartDrag
                                        x: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        y: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        width: dijkstraCell.width
                                        height: dijkstraCell.height
                                        
                                        Drag.active: dijkstraMouseArea.drag.active && 
                                                    cellX === pathfinder.start.x && cellY === pathfinder.start.y
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            if (pathfinder.progress !== 0) return;
                                            
                                            var point = dijkstraCell.mapToItem(dijkstraGrid, dijkstraStartDrag.x + width/2, dijkstraStartDrag.y + height/2);
                                            var newX = Math.floor(point.x / dijkstraGrid.cellSize);
                                            var newY = Math.floor(point.y / dijkstraGrid.cellSize);
                                            
                                            console.log("Updating start position to: (" + newX + "," + newY + ")")
                                            
                                            if (newX >= 0 && newX < pathfinder.gridSize && 
                                                newY >= 0 && newY < pathfinder.gridSize &&
                                                !(newX === pathfinder.end.x && newY === pathfinder.end.y)) {
                                                pathfinder.start = Qt.point(newX, newY);
                                            }
                                        }
                                    }

                                    // 终点拖动
                                    Item {
                                        id: dijkstraEndDrag
                                        x: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        y: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        width: dijkstraCell.width
                                        height: dijkstraCell.height
                                        
                                        Drag.active: dijkstraMouseArea.drag.active && 
                                                    cellX === pathfinder.end.x && cellY === pathfinder.end.y
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            if (pathfinder.progress !== 0) return;
                                            
                                            var point = dijkstraCell.mapToItem(dijkstraGrid, dijkstraEndDrag.x + width/2, dijkstraEndDrag.y + height/2);
                                            var newX = Math.floor(point.x / dijkstraGrid.cellSize);
                                            var newY = Math.floor(point.y / dijkstraGrid.cellSize);
                                            
                                            console.log("Updating end position to: (" + newX + "," + newY + ")")
                                            
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
                                
                                // Greedy 网格 delegate - 简化颜色逻辑
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
                                        else if (cellData.isFinalPath) return "#27ae60";  // 只显示最终路径
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
                                            if (pathfinder.progress === 0) {
                                                if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) {
                                                    drag.target = greedyStartDrag;
                                                } else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) {
                                                    drag.target = greedyEndDrag;
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        id: greedyStartDrag
                                        x: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        y: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        width: greedyCell.width
                                        height: greedyCell.height
                                        
                                        Drag.active: greedyStartDrag.Drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            if (pathfinder.progress !== 0) return;
                                            
                                            var point = greedyCell.mapToItem(greedyGrid, greedyStartDrag.x + width/2, greedyStartDrag.y + height/2);
                                            var newX = Math.floor(point.x / greedyGrid.cellSize);
                                            var newY = Math.floor(point.y / greedyGrid.cellSize);
                                            
                                            if (newX >= 0 && newX < pathfinder.gridSize && 
                                                newY >= 0 && newY < pathfinder.gridSize &&
                                                !(newX === pathfinder.end.x && newY === pathfinder.end.y)) {
                                                pathfinder.start = Qt.point(newX, newY);
                                            }
                                        }
                                    }

                                    Item {
                                        id: greedyEndDrag
                                        x: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        y: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        width: greedyCell.width
                                        height: greedyCell.height
                                        
                                        Drag.active: greedyEndDrag.Drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            if (pathfinder.progress !== 0) return;
                                            
                                            var point = greedyCell.mapToItem(greedyGrid, greedyEndDrag.x + width/2, greedyEndDrag.y + height/2);
                                            var newX = Math.floor(point.x / greedyGrid.cellSize);
                                            var newY = Math.floor(point.y / greedyGrid.cellSize);
                                            
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
                                
                                // A* 网格 delegate - 简化颜色逻辑
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
                                        else if (cellData.isFinalPath) return "#27ae60";  // 只显示最终路径
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
                                            if (pathfinder.progress === 0) {
                                                if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) {
                                                    drag.target = aStarStartDrag;
                                                } else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) {
                                                    drag.target = aStarEndDrag;
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        id: aStarStartDrag
                                        x: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        y: cellX === pathfinder.start.x && cellY === pathfinder.start.y ? 0 : -1000
                                        width: aStarCell.width
                                        height: aStarCell.height
                                        
                                        Drag.active: aStarStartDrag.Drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            if (pathfinder.progress !== 0) return;
                                            
                                            var point = aStarCell.mapToItem(aStarGrid, aStarStartDrag.x + width/2, aStarStartDrag.y + height/2);
                                            var newX = Math.floor(point.x / aStarGrid.cellSize);
                                            var newY = Math.floor(point.y / aStarGrid.cellSize);
                                            
                                            if (newX >= 0 && newX < pathfinder.gridSize && 
                                                newY >= 0 && newY < pathfinder.gridSize &&
                                                !(newX === pathfinder.end.x && newY === pathfinder.end.y)) {
                                                pathfinder.start = Qt.point(newX, newY);
                                            }
                                        }
                                    }

                                    Item {
                                        id: aStarEndDrag
                                        x: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        y: cellX === pathfinder.end.x && cellY === pathfinder.end.y ? 0 : -1000
                                        width: aStarCell.width
                                        height: aStarCell.height
                                        
                                        Drag.active: aStarEndDrag.Drag.active
                                        Drag.hotSpot.x: width / 2
                                        Drag.hotSpot.y: height / 2
                                        
                                        onXChanged: if (Drag.active) updatePosition()
                                        onYChanged: if (Drag.active) updatePosition()
                                        
                                        function updatePosition() {
                                            if (pathfinder.progress !== 0) return;
                                            
                                            var point = aStarCell.mapToItem(aStarGrid, aStarEndDrag.x + width/2, aStarEndDrag.y + height/2);
                                            var newX = Math.floor(point.x / aStarGrid.cellSize);
                                            var newY = Math.floor(point.y / aStarGrid.cellSize);
                                            
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