#include "pathfinder.h"
#include <QTimer>
#include <QDebug>
#include <QMetaObject>
#include <climits>

Pathfinder::Pathfinder(QObject *parent) 
    : QObject(parent), 
      m_gridSize(15), 
      m_start(0,0), 
      m_end(14,14), 
      m_simulationTimer(new QTimer(this)),
      m_dijkstraState([](const Cell* a, const Cell* b) { return a->g > b->g; }),
      m_greedyState([](const Cell* a, const Cell* b) { return a->h > b->h; }),
      m_aStarState([](const Cell* a, const Cell* b) { return a->f > b->f; }),
      m_progress(0),
      m_maxProgress(0),
      m_isRunning(false),
      m_needsPrecomputation(true)
{
    initializeGrids();
    
    connect(m_simulationTimer, &QTimer::timeout, this, [this]() {
        if (m_progress < m_maxProgress) {
            setProgress(m_progress + 1);
        } else {
            stopSimulation();
        }
    });
}

int Pathfinder::gridSize() const {
    return m_gridSize;
}

void Pathfinder::setGridSize(int size) {
    if (m_gridSize != size && size >= 5 && size <= 50) {
        m_gridSize = size;
        m_start = QPoint(0, 0);
        m_end = QPoint(size-1, size-1);
        m_needsPrecomputation = true;
        initializeGrids();
        resetSimulation();
        emit gridSizeChanged();
    }
}

QPoint Pathfinder::start() const {
    return m_start;
}

void Pathfinder::setStart(const QPoint &point) {
    if (m_start != point && 
        point.x() >= 0 && point.x() < m_gridSize && 
        point.y() >= 0 && point.y() < m_gridSize &&
        !(point.x() == m_end.x() && point.y() == m_end.y())) {
        
        m_start = point;
        m_needsPrecomputation = true;
        resetSimulation();
        emit startChanged();
    }
}

QPoint Pathfinder::end() const {
    return m_end;
}

void Pathfinder::setEnd(const QPoint &point) {
    if (m_end != point && 
        point.x() >= 0 && point.x() < m_gridSize && 
        point.y() >= 0 && point.y() < m_gridSize &&
        !(point.x() == m_start.x() && point.y() == m_start.y())) {
        
        m_end = point;
        m_needsPrecomputation = true;
        resetSimulation();
        emit endChanged();
    }
}

QVariantList Pathfinder::dijkstraGrid() const {
    return gridToVariantList(m_dijkstraState.grid);
}

QVariantList Pathfinder::greedyGrid() const {
    return gridToVariantList(m_greedyState.grid);
}

QVariantList Pathfinder::aStarGrid() const {
    return gridToVariantList(m_aStarState.grid);
}

int Pathfinder::progress() const {
    return m_progress;
}

void Pathfinder::setProgress(int progress) {
    if (m_progress != progress && progress >= 0 && progress <= m_maxProgress) {
        m_progress = progress;
        
        // 如果需要进行预计算，则先计算
        if (m_needsPrecomputation) {
            precomputePaths();
            m_needsPrecomputation = false;
        }
        
        // 更新当前步骤的网格状态
        if (m_progress <= m_dijkstraState.currentStep) {
            // 回退到之前的步骤
            initializeGrids();
            for (int i = 0; i < m_progress; i++) {
                if (!m_dijkstraState.finished) {
                    stepAlgorithm(m_dijkstraState, [](int, int, int, int) { return 0; });
                }
                if (!m_greedyState.finished) {
                    stepAlgorithm(m_greedyState, [this](int x1, int y1, int x2, int y2) { 
                        return heuristic(x1, y1, x2, y2); 
                    });
                }
                if (!m_aStarState.finished) {
                    stepAlgorithm(m_aStarState, [this](int x1, int y1, int x2, int y2) { 
                        return heuristic(x1, y1, x2, y2); 
                    });
                }
            }
        } else {
            // 前进到新的步骤
            while (m_dijkstraState.currentStep < m_progress && !m_dijkstraState.finished) {
                stepAlgorithm(m_dijkstraState, [](int, int, int, int) { return 0; });
                m_dijkstraState.currentStep++;
            }
            
            while (m_greedyState.currentStep < m_progress && !m_greedyState.finished) {
                stepAlgorithm(m_greedyState, [this](int x1, int y1, int x2, int y2) { 
                    return heuristic(x1, y1, x2, y2); 
                });
                m_greedyState.currentStep++;
            }
            
            while (m_aStarState.currentStep < m_progress && !m_aStarState.finished) {
                stepAlgorithm(m_aStarState, [this](int x1, int y1, int x2, int y2) { 
                    return heuristic(x1, y1, x2, y2); 
                });
                m_aStarState.currentStep++;
            }
        }
        
        emit progressChanged();
        emit gridChanged();
    }
}

int Pathfinder::maxProgress() const {
    return m_maxProgress;
}

bool Pathfinder::isRunning() const {
    return m_isRunning;
}

void Pathfinder::setIsRunning(bool running) {
    if (m_isRunning != running) {
        m_isRunning = running;
        emit isRunningChanged();
    }
}

void Pathfinder::toggleObstacle(int x, int y) {
    // 只在进度为0时允许修改地图
    if (m_progress == 0 &&
        x >= 0 && x < m_gridSize && y >= 0 && y < m_gridSize &&
        !(x == m_start.x() && y == m_start.y()) && 
        !(x == m_end.x() && y == m_end.y())) {
        
        // 切换障碍物状态
        bool newObstacleState = !m_dijkstraState.grid[y][x].isObstacle;
        m_dijkstraState.grid[y][x].isObstacle = newObstacleState;
        m_greedyState.grid[y][x].isObstacle = newObstacleState;
        m_aStarState.grid[y][x].isObstacle = newObstacleState;
        
        m_needsPrecomputation = true;
        emit gridChanged();
    }
}

void Pathfinder::stepForward() {
    if (m_progress < m_maxProgress) {
        setProgress(m_progress + 1);
    }
}

void Pathfinder::stepBackward() {
    if (m_progress > 0) {
        setProgress(m_progress - 1);
    }
}

void Pathfinder::startSimulation() {
    if (!m_isRunning && m_progress < m_maxProgress) {
        setIsRunning(true);
        m_simulationTimer->start(100); // 适当的速度
    }
}

void Pathfinder::stopSimulation() {
    if (m_isRunning) {
        setIsRunning(false);
        m_simulationTimer->stop();
    }
}

void Pathfinder::resetSimulation() {
    m_progress = 0;
    m_maxProgress = m_gridSize * m_gridSize; // 最大步数
    
    // 重置所有算法状态
    m_dijkstraState.finished = false;
    m_dijkstraState.currentStep = 0;
    m_dijkstraState.stepPaths.clear();
    m_dijkstraState.stepOpenSets.clear();
    m_dijkstraState.stepClosedSets.clear();
    
    m_greedyState.finished = false;
    m_greedyState.currentStep = 0;
    m_greedyState.stepPaths.clear();
    m_greedyState.stepOpenSets.clear();
    m_greedyState.stepClosedSets.clear();
    
    m_aStarState.finished = false;
    m_aStarState.currentStep = 0;
    m_aStarState.stepPaths.clear();
    m_aStarState.stepOpenSets.clear();
    m_aStarState.stepClosedSets.clear();
    
    initializeGrids();
    
    emit progressChanged();
    emit maxProgressChanged();
    emit gridChanged();
}

void Pathfinder::precomputePaths() {
    // 重置状态但不重置网格
    m_dijkstraState.finished = false;
    m_dijkstraState.currentStep = 0;
    m_dijkstraState.path.clear();
    
    m_greedyState.finished = false;
    m_greedyState.currentStep = 0;
    m_greedyState.path.clear();
    
    m_aStarState.finished = false;
    m_aStarState.currentStep = 0;
    m_aStarState.path.clear();
    
    // 重新初始化算法状态（保持障碍物）
    QVector<QVector<Cell>> tempGrid = m_dijkstraState.grid;
    initializeGrids();
    
    // 恢复障碍物状态
    for (int y = 0; y < m_gridSize; ++y) {
        for (int x = 0; x < m_gridSize; ++x) {
            m_dijkstraState.grid[y][x].isObstacle = tempGrid[y][x].isObstacle;
            m_greedyState.grid[y][x].isObstacle = tempGrid[y][x].isObstacle;
            m_aStarState.grid[y][x].isObstacle = tempGrid[y][x].isObstacle;
        }
    }
    
    // 计算最大步数
    m_maxProgress = m_gridSize * m_gridSize;
    emit maxProgressChanged();
}

void Pathfinder::initializeGrids() {
    // 初始化所有网格
    m_dijkstraState.grid.resize(m_gridSize);
    m_greedyState.grid.resize(m_gridSize);
    m_aStarState.grid.resize(m_gridSize);
    
    for (int y = 0; y < m_gridSize; ++y) {
        m_dijkstraState.grid[y].resize(m_gridSize);
        m_greedyState.grid[y].resize(m_gridSize);
        m_aStarState.grid[y].resize(m_gridSize);
        
        for (int x = 0; x < m_gridSize; ++x) {
            // 保留现有的障碍物状态
            bool isObstacle = false;
            if (y < m_dijkstraState.grid.size() && x < m_dijkstraState.grid[y].size()) {
                isObstacle = m_dijkstraState.grid[y][x].isObstacle;
            }
            
            m_dijkstraState.grid[y][x] = Cell();
            m_dijkstraState.grid[y][x].x = x;
            m_dijkstraState.grid[y][x].y = y;
            m_dijkstraState.grid[y][x].isObstacle = isObstacle;
            m_dijkstraState.grid[y][x].g = INT_MAX;
            m_dijkstraState.grid[y][x].f = INT_MAX;
            
            m_greedyState.grid[y][x] = Cell();
            m_greedyState.grid[y][x].x = x;
            m_greedyState.grid[y][x].y = y;
            m_greedyState.grid[y][x].isObstacle = isObstacle;
            m_greedyState.grid[y][x].g = INT_MAX;
            m_greedyState.grid[y][x].f = INT_MAX;
            
            m_aStarState.grid[y][x] = Cell();
            m_aStarState.grid[y][x].x = x;
            m_aStarState.grid[y][x].y = y;
            m_aStarState.grid[y][x].isObstacle = isObstacle;
            m_aStarState.grid[y][x].g = INT_MAX;
            m_aStarState.grid[y][x].f = INT_MAX;
        }
    }
    
    // 初始化开放集合
    while (!m_dijkstraState.openSet.empty()) m_dijkstraState.openSet.pop();
    while (!m_greedyState.openSet.empty()) m_greedyState.openSet.pop();
    while (!m_aStarState.openSet.empty()) m_aStarState.openSet.pop();
    
    // 清空路径
    m_dijkstraState.path.clear();
    m_greedyState.path.clear();
    m_aStarState.path.clear();
    
    // 设置起点
    Cell* startCell = getCell(m_dijkstraState.grid, m_start.x(), m_start.y());
    if (startCell && !startCell->isObstacle) {
        startCell->g = 0;
        startCell->h = heuristic(startCell->x, startCell->y, m_end.x(), m_end.y());
        startCell->f = startCell->g + startCell->h;
        startCell->isOpen = true;
        m_dijkstraState.openSet.push(startCell);
    }
    
    startCell = getCell(m_greedyState.grid, m_start.x(), m_start.y());
    if (startCell && !startCell->isObstacle) {
        startCell->g = 0;
        startCell->h = heuristic(startCell->x, startCell->y, m_end.x(), m_end.y());
        startCell->f = startCell->g + startCell->h;
        startCell->isOpen = true;
        m_greedyState.openSet.push(startCell);
    }
    
    startCell = getCell(m_aStarState.grid, m_start.x(), m_start.y());
    if (startCell && !startCell->isObstacle) {
        startCell->g = 0;
        startCell->h = heuristic(startCell->x, startCell->y, m_end.x(), m_end.y());
        startCell->f = startCell->g + startCell->h;
        startCell->isOpen = true;
        m_aStarState.openSet.push(startCell);
    }
}

int Pathfinder::heuristic(int x1, int y1, int x2, int y2) {
    return qAbs(x1 - x2) + qAbs(y1 - y2);
}

void Pathfinder::reconstructPath(AlgorithmState &state, Cell *current) {
    state.path.clear();
    while (current) {
        state.path.prepend(QPoint(current->x, current->y));
        current = current->parent;
    }
}

void Pathfinder::stepAlgorithm(AlgorithmState &state, const std::function<int(int, int, int, int)>& heuristicFunc) {
    if (state.finished || state.openSet.empty()) {
        state.finished = true;
        return;
    }
    
    // 从开放集合中获取下一个节点
    Cell* current = state.openSet.top();
    state.openSet.pop();
    
    // 如果到达终点
    if (current->x == m_end.x() && current->y == m_end.y()) {
        reconstructPath(state, current);
        state.finished = true;
        return;
    }
    
    // 将当前节点标记为已关闭
    current->isOpen = false;
    current->isClosed = true;
    
    // 检查相邻节点
    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            // 禁止对角线移动
            if (dx != 0 && dy != 0) continue;
            
            // 跳过自身
            if (dx == 0 && dy == 0) continue;
            
            int nx = current->x + dx;
            int ny = current->y + dy;
            
            // 检查边界
            if (nx < 0 || nx >= m_gridSize || ny < 0 || ny >= m_gridSize) continue;
            
            Cell* neighbor = getCell(state.grid, nx, ny);
            if (!neighbor) continue;
            
            // 跳过障碍物和已关闭的节点
            if (neighbor->isObstacle || neighbor->isClosed) continue;
            
            // 计算新的g值
            int tentativeG = current->g + 1;
            
            // 如果新路径更好，更新邻居节点
            if (tentativeG < neighbor->g) {
                neighbor->parent = current;
                neighbor->g = tentativeG;
                neighbor->h = heuristicFunc(neighbor->x, neighbor->y, m_end.x(), m_end.y());
                neighbor->f = neighbor->g + neighbor->h;
                
                if (!neighbor->isOpen) {
                    neighbor->isOpen = true;
                    state.openSet.push(neighbor);
                }
            }
        }
    }
}

QVariantList Pathfinder::gridToVariantList(const QVector<QVector<Cell>>& grid) const {
    QVariantList gridList;
    for (int y = 0; y < m_gridSize; ++y) {
        QVariantList row;
        for (int x = 0; x < m_gridSize; ++x) {
            const Cell &cell = grid[y][x];
            
            row.append(QVariantMap{
                {"x", x},
                {"y", y},
                {"isObstacle", cell.isObstacle},
                {"g", cell.g == INT_MAX ? 0 : cell.g},
                {"h", cell.h},
                {"f", cell.f == INT_MAX ? 0 : cell.f},
                {"isOpen", cell.isOpen},
                {"isClosed", cell.isClosed}
            });
        }
        gridList.append(row);
    }
    return gridList;
}

Pathfinder::Cell* Pathfinder::getCell(QVector<QVector<Pathfinder::Cell>>& grid, int x, int y) {
    if (x >= 0 && x < m_gridSize && y >= 0 && y < m_gridSize) {
        return &grid[y][x];
    }
    return nullptr;
}

bool Pathfinder::isInPath(int x, int y, const QString& algorithm) const {
    const QVector<QPoint>* path = nullptr;
    
    if (algorithm == "dijkstra") {
        path = &m_dijkstraState.path;
    } else if (algorithm == "greedy") {
        path = &m_greedyState.path;
    } else if (algorithm == "astar") {
        path = &m_aStarState.path;
    }
    
    if (path) {
        for (const QPoint &p : *path) {
            if (p.x() == x && p.y() == y) return true;
        }
    }
    return false;
}