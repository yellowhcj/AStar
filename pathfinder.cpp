#include "pathfinder.h"
#include <QTimer>
#include <QDebug>

Pathfinder::Pathfinder(QObject *parent) : QObject(parent), m_gridSize(20), m_start(0,0), m_end(19,19), m_timer(new QTimer(this)) {
    qDebug() << "[Pathfinder] Constructor called";
    initializeGrid();
    connect(m_timer, &QTimer::timeout, this, [this]() {
        if (!m_path.isEmpty()) {
            m_path.pop_back();
            emit gridChanged();
        } else {
            m_timer->stop();
        }
    });
}

int Pathfinder::gridSize() const {
    return m_gridSize;
}

void Pathfinder::setGridSize(int size) {
    if (m_gridSize != size) {
        m_gridSize = size;
        initializeGrid();
        emit gridSizeChanged();
        emit gridChanged();
    }
}

QPoint Pathfinder::start() const {
    return m_start;
}

void Pathfinder::setStart(const QPoint &point) {
    if (m_start != point) {
        m_start = point;
        emit startChanged();
    }
}

QPoint Pathfinder::end() const {
    return m_end;
}

void Pathfinder::setEnd(const QPoint &point) {
    if (m_end != point) {
        m_end = point;
        emit endChanged();
    }
}

QVariantList Pathfinder::grid() const {
    QVariantList gridList;
    for (int y = 0; y < m_gridSize; ++y) {
        QVariantList row;
        for (int x = 0; x < m_gridSize; ++x) {
            const Cell &cell = m_grid[y][x];
            row.append(QVariantMap{
                {"x", x},
                {"y", y},
                {"isObstacle", cell.isObstacle},
                {"g", cell.g},
                {"h", cell.h},
                {"f", cell.f},
                {"isOpen", cell.isOpen},
                {"isClosed", cell.isClosed}
            });
        }
        gridList.append(row);
    }
    return gridList;
}

void Pathfinder::toggleObstacle(int x, int y) {
    if (x >= 0 && x < m_gridSize && y >= 0 && y < m_gridSize) {
        m_grid[y][x].isObstacle = !m_grid[y][x].isObstacle;
        emit gridChanged();
    }
}

void Pathfinder::findPath() {
    qDebug() << "[Pathfinder] findPath called";
    m_path.clear();
    // 初始化网格
    initializeGrid();
    
    // 创建openSet和closedSet
    auto cmp = [](const Cell* a, const Cell* b) { return a->f > b->f; };
    std::priority_queue<Cell*, std::vector<Cell*>, decltype(cmp)> openSet(cmp);
    
    // 获取起点和终点单元格
    Cell* startCell = &m_grid[m_start.y()][m_start.x()];
    Cell* endCell = &m_grid[m_end.y()][m_end.x()];
    
    // 设置起点
    startCell->g = 0;
    startCell->h = heuristic(startCell->x, startCell->y, endCell->x, endCell->y);
    startCell->f = startCell->g + startCell->h;
    startCell->isOpen = true;
    openSet.push(startCell);
    
    // A*主循环
    while (!openSet.empty()) {
        // 从openSet中获取f值最小的节点
        Cell* current = openSet.top();
        openSet.pop();
        
        // 如果是目标节点，重构路径并退出
        if (current == endCell) {
            reconstructPath(current);
            emit gridChanged();
            return;
        }
        
        // 将当前节点移出openSet，加入closedSet
        current->isOpen = false;
        current->isClosed = true;
        
        // 检查相邻节点
        for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
                // 跳过对角线移动（简化版）或允许对角线
                if (dx != 0 && dy != 0) continue; // 禁止对角线移动
                
                int nx = current->x + dx;
                int ny = current->y + dy;
                
                // 检查边界
                if (nx < 0 || nx >= m_gridSize || ny < 0 || ny >= m_gridSize) continue;
                
                Cell* neighbor = &m_grid[ny][nx];
                
                // 跳过障碍物和已关闭的节点
                if (neighbor->isObstacle || neighbor->isClosed) continue;
                
                // 计算新的g值
                int tentativeG = current->g + 1; // 假设移动代价为1
                
                // 如果新路径更好，更新邻居节点
                if (!neighbor->isOpen || tentativeG < neighbor->g) {
                    neighbor->parent = current;
                    neighbor->g = tentativeG;
                    neighbor->h = heuristic(neighbor->x, neighbor->y, endCell->x, endCell->y);
                    neighbor->f = neighbor->g + neighbor->h;
                    
                    if (!neighbor->isOpen) {
                        neighbor->isOpen = true;
                        openSet.push(neighbor);
                    }
                }
            }
        }
    }
    
    // 如果没有找到路径
    qDebug() << "[Pathfinder] No path found!";
    emit gridChanged();
}

void Pathfinder::initializeGrid() {
    m_grid.resize(m_gridSize);
    for (int y = 0; y < m_gridSize; ++y) {
        m_grid[y].resize(m_gridSize);
        for (int x = 0; x < m_gridSize; ++x) {
            bool isObstacle = m_grid[y][x].isObstacle;
            m_grid[y][x] = {x, y, isObstacle, 0, 0, 0, false, false, nullptr};
        }
    }
}

int Pathfinder::heuristic(int x1, int y1, int x2, int y2) {
    return qAbs(x1 - x2) + qAbs(y1 - y2);
}

void Pathfinder::reconstructPath(Cell *current) {
    if (!current) return;
    while (current->parent) {
        m_path.append(QPoint(current->x, current->y));
        current = current->parent;
    }
    // 添加起点
    if (!m_path.isEmpty()) {
        m_path.append(QPoint(m_start.x(), m_start.y()));
    }
}

void Pathfinder::stepAStar() {
    // TODO: 实现A*步骤
}

bool Pathfinder::isInPath(int x, int y) const {
    for (const QPoint &p : m_path) {
        if (p.x() == x && p.y() == y) return true;
    }
    return false;
}
