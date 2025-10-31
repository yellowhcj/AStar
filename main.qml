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

    component DraggableIcon : Rectangle {
        required property string type // "start" or "end"
        required property point gridPos
        required property var gridParent
        
        property bool isDragging: false
        property point dragStartPos
        property point startCellPos // 记录拖动开始时的格子位置
        
        width: gridParent.cellSize * 0.8
        height: gridParent.cellSize * 0.8
        radius: width / 2
        color: type === "start" ? "#f39c12" : "#e74c3c"
        border.color: "white"
        border.width: 2
        z: 100
        
        // 修复：使用格子中心点定位
        x: (gridPos.x * gridParent.cellSize) + (gridParent.cellSize - width) / 2
        y: (gridPos.y * gridParent.cellSize) + (gridParent.cellSize - height) / 2
        
        Text {
            anchors.centerIn: parent
            text: type === "start" ? "★" : "✖"
            color: "white"
            font.pixelSize: parent.height * 0.6
            font.bold: true
        }
        
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: parent
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: gridParent.width - parent.width
            drag.maximumY: gridParent.height - parent.height
            
            onPressed: {
                parent.isDragging = true
                parent.dragStartPos = Qt.point(parent.x, parent.y)
                parent.startCellPos = gridPos
                parent.z = 1000
            }
            
            onReleased: {
                parent.isDragging = false
                parent.z = 100
                
                // 修复：使用图标中心点计算格子位置
                var iconCenterX = parent.x + parent.width / 2
                var iconCenterY = parent.y + parent.height / 2
                var newX = Math.floor(iconCenterX / gridParent.cellSize)
                var newY = Math.floor(iconCenterY / gridParent.cellSize)
                
                console.log("Icon center: (" + iconCenterX + "," + iconCenterY + ")")
                console.log("Grid cell size: " + gridParent.cellSize)
                console.log("Calculated position: (" + newX + "," + newY + ")")
                
                // 确保在网格范围内
                if (newX >= 0 && newX < pathfinder.gridSize && 
                    newY >= 0 && newY < pathfinder.gridSize) {
                    
                    // 检查目标位置是否有效
                    var targetCell = pathfinder.getDijkstraCell(newX, newY)
                    var isValidPosition = targetCell && !targetCell.isObstacle
                    
                    if (isValidPosition) {
                        // 检查不会与另一个点重叠
                        if (type === "start") {
                            if (!(newX === pathfinder.end.x && newY === pathfinder.end.y)) {
                                console.log("Moving start to: (" + newX + "," + newY + ")")
                                pathfinder.start = Qt.point(newX, newY)
                            } else {
                                console.log("Cannot move start to end position")
                                isValidPosition = false
                            }
                        } else {
                            if (!(newX === pathfinder.start.x && newY === pathfinder.start.y)) {
                                console.log("Moving end to: (" + newX + "," + newY + ")")
                                pathfinder.end = Qt.point(newX, newY)
                            } else {
                                console.log("Cannot move end to start position")
                                isValidPosition = false
                            }
                        }
                    } else {
                        console.log("Target position is obstacle or invalid")
                    }
                    
                    // 如果放置位置无效，回到原位置
                    if (!isValidPosition) {
                        if (type === "start") {
                            parent.x = (pathfinder.start.x * gridParent.cellSize) + (gridParent.cellSize - parent.width) / 2
                            parent.y = (pathfinder.start.y * gridParent.cellSize) + (gridParent.cellSize - parent.height) / 2
                        } else {
                            parent.x = (pathfinder.end.x * gridParent.cellSize) + (gridParent.cellSize - parent.width) / 2
                            parent.y = (pathfinder.end.y * gridParent.cellSize) + (gridParent.cellSize - parent.height) / 2
                        }
                    }
                } else {
                    console.log("Position out of grid bounds")
                    // 回到原位置
                    if (type === "start") {
                        parent.x = (pathfinder.start.x * gridParent.cellSize) + (gridParent.cellSize - parent.width) / 2
                        parent.y = (pathfinder.start.y * gridParent.cellSize) + (gridParent.cellSize - parent.height) / 2
                    } else {
                        parent.x = (pathfinder.end.x * gridParent.cellSize) + (gridParent.cellSize - parent.width) / 2
                        parent.y = (pathfinder.end.y * gridParent.cellSize) + (gridParent.cellSize - parent.height) / 2
                    }
                }
            }
            
            // 添加拖动过程中的实时位置反馈
            onPositionChanged: {
                if (drag.active) {
                    var currentCenterX = parent.x + parent.width / 2
                    var currentCenterY = parent.y + parent.height / 2
                    var hoverX = Math.floor(currentCenterX / gridParent.cellSize)
                    var hoverY = Math.floor(currentCenterY / gridParent.cellSize)
                    
                    // 可以在这里添加视觉反馈，比如高亮悬停的格子
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // 标题区域
        Rectangle {
            Layout.fillWidth: true
            height: 80
            radius: 12
            color: "#ffffff"
            border.color: "#e0e0e0"
            border.width: 1
            
            // 简单的阴影效果
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                radius: parent.radius
                color: "#20000000"
                z: -1
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                
                ColumnLayout {
                    spacing: 4
                    Text {
                        text: "Pathfinding Algorithms Visualizer"
                        font.bold: true
                        font.pixelSize: 20
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
                    spacing: 20
                    
                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight
                        
                        Grid {
                            columns: 3
                            spacing: 12
                            
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
                        font.pixelSize: 14
                        implicitWidth: 120
                        implicitHeight: 36
                        
                        background: Rectangle {
                            color: parent.pressed ? "#95a5a6" : "#bdc3c7"
                            radius: 6
                            border.color: "#7f8c8d"
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "#2c3e50"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
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
                        font.pixelSize: 14
                        implicitWidth: 120
                        implicitHeight: 36
                        
                        background: Rectangle {
                            color: parent.pressed ? "#95a5a6" : "#bdc3c7"
                            radius: 6
                            border.color: "#7f8c8d"
                            border.width: 1
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: "#2c3e50"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.bold: true
                        }
                        
                        onClicked: {
                            console.log("=== ALGORITHM DEBUG BUTTON CLICKED ===")
                            pathfinder.debugPrintGrids()
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            // Dijkstra 网格部分 - 修改为正方形容器
            ColumnLayout {
                Layout.preferredWidth: (parent.width - 32) / 3
                Layout.fillHeight: true
                spacing: 8

                Text {
                    text: "Dijkstra/BFS (G cost)"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    color: "#2c3e50"
                    font.pixelSize: 16
                }

                Rectangle {
                    Layout.fillWidth: true
                    // 关键修改：设置固定的宽高比，确保正方形
                    Layout.preferredHeight: parent.width
                    border.color: "#34495e"
                    border.width: 2
                    radius: 8
                    color: "transparent"
                    
                    // 简单的阴影效果
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        radius: parent.radius
                        color: "#20000000"
                        z: -1
                    }

                    Item {
                        id: dijkstraGridContainer
                        anchors.fill: parent
                        anchors.margins: 12

                        Grid {
                            id: dijkstraGrid
                            anchors.centerIn: parent
                            rows: pathfinder.gridSize
                            columns: pathfinder.gridSize
                            // 关键修改：确保网格本身是正方形
                            property real cellSize: Math.min(parent.width, parent.height) / pathfinder.gridSize
                            width: cellSize * pathfinder.gridSize
                            height: cellSize * pathfinder.gridSize

                            Repeater {
                                id: dijkstraGridRepeater
                                model: pathfinder.gridSize * pathfinder.gridSize
                                
                                delegate: Rectangle {
                                    id: dijkstraCell
                                    width: dijkstraGrid.cellSize
                                    height: dijkstraGrid.cellSize
                                    border.color: "#bdc3c7"
                                    border.width: 0.5
                                    radius: 2

                                    property int cellX: index % pathfinder.gridSize
                                    property int cellY: Math.floor(index / pathfinder.gridSize)
                                    
                                    property var cellData: pathfinder.getDijkstraCell(cellX, cellY)

                                    color: {
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "transparent";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "transparent";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isFinalPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        onEntered: {
                                            dijkstraCell.border.width = 2
                                            dijkstraCell.border.color = "#e74c3c"
                                        }
                                        
                                        onExited: {
                                            dijkstraCell.border.width = 0.5
                                            dijkstraCell.border.color = "#bdc3c7"
                                        }
                                        
                                        onClicked: {
                                            console.log("=== DIJKSTRA CELL CLICKED ===")
                                            console.log("Cell coordinates: (" + cellX + "," + cellY + ")")
                                            
                                            if (!(cellX === pathfinder.start.x && cellY === pathfinder.start.y) &&
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)) {
                                                console.log("Calling toggleObstacle...")
                                                pathfinder.toggleObstacle(cellX, cellY);
                                            } else {
                                                console.log("Cell is start or end position, skipping toggle")
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (cellData.isObstacle) return "█";
                                            else if (cellData.isOpen || cellData.isClosed) {
                                                return cellData.g > 0 && cellData.g < 999 ? cellData.g : "";
                                            }
                                            return "";
                                        }
                                        font.pixelSize: Math.min(dijkstraCell.width, dijkstraCell.height) * 0.4
                                        color: "white"
                                        font.bold: true
                                        visible: !(cellX === pathfinder.start.x && cellY === pathfinder.start.y) && 
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)
                                    }
                                }
                            }
                        }

                        // 起点图标
                        DraggableIcon {
                            id: dijkstraStartIcon
                            type: "start"
                            gridPos: pathfinder.start
                            gridParent: dijkstraGrid
                        }

                        // 终点图标
                        DraggableIcon {
                            id: dijkstraEndIcon
                            type: "end"
                            gridPos: pathfinder.end
                            gridParent: dijkstraGrid
                        }
                    }
                }
            }

            // Greedy 网格部分 - 修改为正方形容器
            ColumnLayout {
                Layout.preferredWidth: (parent.width - 32) / 3
                Layout.fillHeight: true
                spacing: 8

                Text {
                    text: "Greedy Best-First (H cost)"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    color: "#2c3e50"
                    font.pixelSize: 16
                }

                Rectangle {
                    Layout.fillWidth: true
                    // 关键修改：设置固定的宽高比，确保正方形
                    Layout.preferredHeight: parent.width
                    border.color: "#34495e"
                    border.width: 2
                    radius: 8
                    color: "transparent"
                    
                    // 简单的阴影效果
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        radius: parent.radius
                        color: "#20000000"
                        z: -1
                    }

                    Item {
                        id: greedyGridContainer
                        anchors.fill: parent
                        anchors.margins: 12

                        Grid {
                            id: greedyGrid
                            anchors.centerIn: parent
                            rows: pathfinder.gridSize
                            columns: pathfinder.gridSize
                            // 关键修改：确保网格本身是正方形
                            property real cellSize: Math.min(parent.width, parent.height) / pathfinder.gridSize
                            width: cellSize * pathfinder.gridSize
                            height: cellSize * pathfinder.gridSize

                            Repeater {
                                id: greedyGridRepeater
                                model: pathfinder.gridSize * pathfinder.gridSize
                                
                                delegate: Rectangle {
                                    id: greedyCell
                                    width: greedyGrid.cellSize
                                    height: greedyGrid.cellSize
                                    border.color: "#bdc3c7"
                                    border.width: 0.5
                                    radius: 2

                                    property int cellX: index % pathfinder.gridSize
                                    property int cellY: Math.floor(index / pathfinder.gridSize)
                                    
                                    property var cellData: pathfinder.getGreedyCell(cellX, cellY)

                                    color: {
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "transparent";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "transparent";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isFinalPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        onEntered: {
                                            greedyCell.border.width = 2
                                            greedyCell.border.color = "#e74c3c"
                                        }
                                        
                                        onExited: {
                                            greedyCell.border.width = 0.5
                                            greedyCell.border.color = "#bdc3c7"
                                        }
                                        
                                        onClicked: {
                                            console.log("=== GREEDY CELL CLICKED ===")
                                            console.log("Cell coordinates: (" + cellX + "," + cellY + ")")
                                            
                                            if (!(cellX === pathfinder.start.x && cellY === pathfinder.start.y) &&
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)) {
                                                console.log("Calling toggleObstacle...")
                                                pathfinder.toggleObstacle(cellX, cellY);
                                            } else {
                                                console.log("Cell is start or end position, skipping toggle")
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (cellData.isObstacle) return "█";
                                            else if (cellData.isOpen || cellData.isClosed) {
                                                return cellData.h > 0 ? cellData.h : "";
                                            }
                                            return "";
                                        }
                                        font.pixelSize: Math.min(greedyCell.width, greedyCell.height) * 0.4
                                        color: "white"
                                        font.bold: true
                                        visible: !(cellX === pathfinder.start.x && cellY === pathfinder.start.y) && 
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)
                                    }
                                }
                            }
                        }

                        // 起点图标
                        DraggableIcon {
                            id: greedyStartIcon
                            type: "start"
                            gridPos: pathfinder.start
                            gridParent: greedyGrid
                        }

                        // 终点图标
                        DraggableIcon {
                            id: greedyEndIcon
                            type: "end"
                            gridPos: pathfinder.end
                            gridParent: greedyGrid
                        }
                    }
                }
            }

            // A* 网格部分 - 修改为正方形容器
            ColumnLayout {
                Layout.preferredWidth: (parent.width - 32) / 3
                Layout.fillHeight: true
                spacing: 8

                Text {
                    text: "A* (F cost)"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    color: "#2c3e50"
                    font.pixelSize: 16
                }

                Rectangle {
                    Layout.fillWidth: true
                    // 关键修改：设置固定的宽高比，确保正方形
                    Layout.preferredHeight: parent.width
                    border.color: "#34495e"
                    border.width: 2
                    radius: 8
                    color: "transparent"
                    
                    // 简单的阴影效果
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 2
                        radius: parent.radius
                        color: "#20000000"
                        z: -1
                    }

                    Item {
                        id: aStarGridContainer
                        anchors.fill: parent
                        anchors.margins: 12

                        Grid {
                            id: aStarGrid
                            anchors.centerIn: parent
                            rows: pathfinder.gridSize
                            columns: pathfinder.gridSize
                            // 关键修改：确保网格本身是正方形
                            property real cellSize: Math.min(parent.width, parent.height) / pathfinder.gridSize
                            width: cellSize * pathfinder.gridSize
                            height: cellSize * pathfinder.gridSize

                            Repeater {
                                id: aStarGridRepeater
                                model: pathfinder.gridSize * pathfinder.gridSize
                                
                                delegate: Rectangle {
                                    id: aStarCell
                                    width: aStarGrid.cellSize
                                    height: aStarGrid.cellSize
                                    border.color: "#bdc3c7"
                                    border.width: 0.5
                                    radius: 2

                                    property int cellX: index % pathfinder.gridSize
                                    property int cellY: Math.floor(index / pathfinder.gridSize)
                                    
                                    property var cellData: pathfinder.getAStarCell(cellX, cellY)

                                    color: {
                                        if (cellX === pathfinder.start.x && cellY === pathfinder.start.y) return "transparent";
                                        else if (cellX === pathfinder.end.x && cellY === pathfinder.end.y) return "transparent";
                                        else if (cellData.isObstacle) return "#34495e";
                                        else if (cellData.isFinalPath) return "#27ae60";
                                        else if (cellData.isClosed) return "#9b59b6";
                                        else if (cellData.isOpen) return "#3498db";
                                        else return "#ecf0f1";
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        
                                        onEntered: {
                                            aStarCell.border.width = 2
                                            aStarCell.border.color = "#e74c3c"
                                        }
                                        
                                        onExited: {
                                            aStarCell.border.width = 0.5
                                            aStarCell.border.color = "#bdc3c7"
                                        }
                                        
                                        onClicked: {
                                            console.log("=== A* CELL CLICKED ===")
                                            console.log("Cell coordinates: (" + cellX + "," + cellY + ")")
                                            
                                            if (!(cellX === pathfinder.start.x && cellY === pathfinder.start.y) &&
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)) {
                                                console.log("Calling toggleObstacle...")
                                                pathfinder.toggleObstacle(cellX, cellY);
                                            } else {
                                                console.log("Cell is start or end position, skipping toggle")
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: {
                                            if (cellData.isObstacle) return "█";
                                            else if (cellData.isOpen || cellData.isClosed) {
                                                return cellData.f > 0 && cellData.f < 999 ? cellData.f : "";
                                            }
                                            return "";
                                        }
                                        font.pixelSize: Math.min(aStarCell.width, aStarCell.height) * 0.4
                                        color: "white"
                                        font.bold: true
                                        visible: !(cellX === pathfinder.start.x && cellY === pathfinder.start.y) && 
                                                !(cellX === pathfinder.end.x && cellY === pathfinder.end.y)
                                    }
                                }
                            }
                        }

                        // 起点图标
                        DraggableIcon {
                            id: aStarStartIcon
                            type: "start"
                            gridPos: pathfinder.start
                            gridParent: aStarGrid
                        }

                        // 终点图标
                        DraggableIcon {
                            id: aStarEndIcon
                            type: "end"
                            gridPos: pathfinder.end
                            gridParent: aStarGrid
                        }
                    }
                }
            }
        }

        // 进度控制区域
        Rectangle {
            Layout.fillWidth: true
            height: 120
            radius: 12
            color: "#ffffff"
            border.color: "#e0e0e0"
            border.width: 1
            
            // 简单的阴影效果
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                radius: parent.radius
                color: "#20000000"
                z: -1
            }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

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
                        // 如果处于自动前进状态，停止它
                        if (pathfinder.isRunning) {
                            pathfinder.stopSimulation()
                        }
                        pathfinder.progress = value
                    }

                    // 添加按下和释放事件处理
                    onPressedChanged: {
                        if (pressed && pathfinder.isRunning) {
                            pathfinder.stopSimulation()
                        }
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

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 12

                    ControlButton {
                        text: "⏪ Step Back"
                        onClicked: {
                            // 如果处于自动前进状态，停止它
                            if (pathfinder.isRunning) {
                                pathfinder.stopSimulation()
                            }
                            pathfinder.stepBackward()
                        }
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
                        onClicked: {
                            // 如果处于自动前进状态，停止它
                            if (pathfinder.isRunning) {
                                pathfinder.stopSimulation()
                            }
                            pathfinder.stepForward()
                        }
                        enabled: pathfinder.progress < pathfinder.maxProgress
                        backgroundColor: "#3498db"
                    }

                    ControlButton {
                        text: "🗑️ Clear Walls"
                        onClicked: pathfinder.clearAllObstacles()
                        backgroundColor: "#e67e22"
                    }

                    ControlButton {
                        text: "🔄 Reset"
                        onClicked: pathfinder.resetSimulation()
                        backgroundColor: "#f39c12"
                    }
                }
            }
        }

        // 提示文本
        Text {
            text: "💡 Click any grid to toggle walls • Drag ★ and ✖ icons to move start/end points • Use 'Clear Walls' to remove all obstacles"
            font.pixelSize: 12
            color: "#27ae60"
            font.italic: true
            Layout.alignment: Qt.AlignHCenter
        }
    }

    component LegendItem: RowLayout {
        required property color color
        required property string text
        
        spacing: 8
        
        Rectangle {
            width: 16
            height: 16
            color: parent.color
            radius: 3
            border.width: 1
            border.color: "#bdc3c7"
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