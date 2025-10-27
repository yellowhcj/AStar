import QtQuick
import QtQuick.Window
import QtQuick.Controls
import AStar 1.0

Window {
    width: 800
    height: 800
    visible: true
    title: "A* Algorithm Visualizer"

    Pathfinder {
        id: pathfinder
        gridSize: 20
    }

    Grid {
        id: grid
        anchors.fill: parent
        rows: pathfinder.gridSize
        columns: pathfinder.gridSize

        Repeater {
            model: pathfinder.gridSize * pathfinder.gridSize
            delegate: Rectangle {
                width: grid.width / pathfinder.gridSize
                height: grid.height / pathfinder.gridSize
                border.color: "black"
                border.width: 1

                // ⚠️ 改名以避免覆盖 Item.x/y（FINAL 属性）
                property int cellX: index % pathfinder.gridSize
                property int cellY: Math.floor(index / pathfinder.gridSize)
                property var cellData: {
                    // 修复变量名引用错误，使用cellX和cellY而不是rowIndex/colIndex
                    var gridData = pathfinder.grid;
                    if (gridData && gridData[cellY] && gridData[cellY][cellX] !== undefined) {
                        return gridData[cellY][cellX];
                    } else {
                        return {isObstacle: false, isOpen: false, isClosed: false, g: 0, h: 0, f: 0};
                    }
                }

                color: {
                    if (cellData.isObstacle) return "darkgray";
                    else if (pathfinder.isInPath(cellX, cellY)) return "green";
                    else if (cellData.isOpen) return "lightblue";
                    else if (cellData.isClosed) return "lightcoral";
                    else return "white";
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: pathfinder.toggleObstacle(cellX, cellY)
                }

                Text {
                    anchors.centerIn: parent
                    text: "G:" + cellData.g + "\nH:" + cellData.h + "\nF:" + cellData.f
                    font.pixelSize: 8
                }
            }
        }
    }

    // ✅ 改写按钮，避免 FINAL 冲突 + 提升视觉效果
    Button {
        id: findButton
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 10
        }

        text: "Find Path"
        onClicked: pathfinder.findPath()

        background: Rectangle {
            radius: 4
            color: "#0078D4"
            border.color: "#004E8C"
        }

        contentItem: Text {
            text: findButton.text
            anchors.centerIn: parent
            color: "white"
            font.bold: true
        }
    }
}