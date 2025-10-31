#include "pathfinder.h"
#include <QTimer>
#include <QDebug>
#include <QMetaObject>
#include <climits>
#include <iostream>

Pathfinder::Pathfinder(QObject *parent) 
    : QObject(parent), 
      m_gridSize(15), 
      m_start(0,0), 
      m_end(14,14), 
      m_simulationTimer(new QTimer(this)),
      m_dijkstraState([](Cell* a, Cell* b) { return a->g > b->g; }),
      m_greedyState([](Cell* a, Cell* b) { return a->h > b->h; }),
      m_aStarState([](Cell* a, Cell* b) { return a->f > b->f; }),
      m_progress(0),
      m_maxProgress(0),
      m_isRunning(false),
      m_needsRecomputation(true)
{
    std::cout << "=== PATHFINDER CONSTRUCTOR ===" << std::endl;
    
    // 初始化障碍物网格
    m_obstacles.resize(m_gridSize);
    for (int i = 0; i < m_gridSize; ++i) {
        m_obstacles[i].resize(m_gridSize);
        for (int j = 0; j < m_gridSize; ++j) {
            m_obstacles[i][j] = false;
        }
    }
    
    std::cout << "Calling recomputeAllAlgorithms from constructor..." << std::endl;
    recomputeAllAlgorithms();
    std::cout << "Constructor finished." << std::endl;
    
    connect(m_simulationTimer, &QTimer::timeout, this, [this]() {
        if (m_progress < m_maxProgress) {
            setProgress(m_progress + 1);
        } else {
            stopSimulation();
        }
    });
    
    // 设置定时器间隔为50ms
    m_simulationTimer->setInterval(50);
}

int Pathfinder::gridSize() const {
    return m_gridSize;
}

void Pathfinder::setGridSize(int size) {
    if (m_gridSize != size && size >= 5 && size <= 30) {
        m_gridSize = size;
        m_start = QPoint(0, 0);
        m_end = QPoint(size-1, size-1);
        
        m_obstacles.resize(m_gridSize);
        for (int i = 0; i < m_gridSize; ++i) {
            m_obstacles[i].resize(m_gridSize);
            for (int j = 0; j < m_gridSize; ++j) {
                m_obstacles[i][j] = false;
            }
        }
        
        m_needsRecomputation = true;
        resetSimulation();
        emit gridSizeChanged();
    }
}

QPoint Pathfinder::start() const {
    return m_start;
}

void Pathfinder::setStart(const QPoint &point) {
    std::cout << "=== SET START CALLED ===" << std::endl;
    std::cout << "New start: (" << point.x() << "," << point.y() << ")" << std::endl;
    std::cout << "Current start: (" << m_start.x() << "," << m_start.y() << ")" << std::endl;
    std::cout << "Current progress: " << m_progress << std::endl;
    
    if (m_start != point && 
        point.x() >= 0 && point.x() < m_gridSize && 
        point.y() >= 0 && point.y() < m_gridSize &&
        !m_obstacles[point.y()][point.x()] &&
        !(point.x() == m_end.x() && point.y() == m_end.y())) {
        
        m_start = point;
        m_needsRecomputation = true;
        std::cout << "✅ Start position updated" << std::endl;
        
        // 保存当前进度
        int oldProgress = m_progress;
        
        recomputeAllAlgorithms();
        
        // 如果旧进度大于新最大进度，跳到最后一步
        if (oldProgress > m_maxProgress) {
            setProgress(m_maxProgress);
        } else {
            setProgress(oldProgress);
        }
        
        emit startChanged();
    } else {
        std::cout << "❌ Cannot set start - invalid conditions" << std::endl;
    }
    std::cout << "=== SET START FINISHED ===" << std::endl;
}

QPoint Pathfinder::end() const {
    return m_end;
}

void Pathfinder::setEnd(const QPoint &point) {
    std::cout << "=== SET END CALLED ===" << std::endl;
    std::cout << "New end: (" << point.x() << "," << point.y() << ")" << std::endl;
    std::cout << "Current end: (" << m_end.x() << "," << m_end.y() << ")" << std::endl;
    std::cout << "Current progress: " << m_progress << std::endl;
    
    if (m_end != point && 
        point.x() >= 0 && point.x() < m_gridSize && 
        point.y() >= 0 && point.y() < m_gridSize &&
        !m_obstacles[point.y()][point.x()] &&
        !(point.x() == m_start.x() && point.y() == m_start.y())) {
        
        m_end = point;
        m_needsRecomputation = true;
        std::cout << "✅ End position updated" << std::endl;
        
        // 保存当前进度
        int oldProgress = m_progress;
        
        recomputeAllAlgorithms();
        
        // 如果旧进度大于新最大进度，跳到最后一步
        if (oldProgress > m_maxProgress) {
            setProgress(m_maxProgress);
        } else {
            setProgress(oldProgress);
        }
        
        emit endChanged();
    } else {
        std::cout << "❌ Cannot set end - invalid conditions" << std::endl;
    }
    std::cout << "=== SET END FINISHED ===" << std::endl;
}

int Pathfinder::progress() const {
    return m_progress;
}

void Pathfinder::setProgress(int progress) {
    if (m_progress != progress && progress >= 0 && progress <= m_maxProgress) {
        m_progress = progress;
        
        std::cout << "setProgress: " << progress 
                  << ", Dijkstra steps: " << m_dijkstraState.stepGrids.size()
                  << ", Greedy steps: " << m_greedyState.stepGrids.size()
                  << ", A* steps: " << m_aStarState.stepGrids.size() << std::endl;
        
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

void Pathfinder::toggleObstacle(int x, int y) {
    std::cout << "=== TOGGLE OBSTACLE CALLED ===" << std::endl;
    std::cout << "Coordinates: (" << x << "," << y << ")" << std::endl;
    std::cout << "Current progress: " << m_progress << std::endl;
    std::cout << "Start position: (" << m_start.x() << "," << m_start.y() << ")" << std::endl;
    std::cout << "End position: (" << m_end.x() << "," << m_end.y() << ")" << std::endl;
    std::cout << "Grid bounds: 0 to " << m_gridSize-1 << std::endl;
    
    // 移除进度限制，允许在任何步骤修改
    if (x >= 0 && x < m_gridSize && y >= 0 && y < m_gridSize &&
        !(x == m_start.x() && y == m_start.y()) && 
        !(x == m_end.x() && y == m_end.y())) {
        
        bool newState = !m_obstacles[y][x];
        m_obstacles[y][x] = newState;
        std::cout << "✅ Obstacle toggled at (" << x << "," << y << ") to: " << newState << std::endl;
        
        m_needsRecomputation = true;
        
        // 保存当前进度
        int oldProgress = m_progress;
        
        // 重新计算所有算法
        recomputeAllAlgorithms();
        
        // 如果旧进度大于新最大进度，跳到最后一步
        if (oldProgress > m_maxProgress) {
            setProgress(m_maxProgress);
        } else {
            // 否则保持当前进度（重新计算会重置为0，需要恢复）
            setProgress(oldProgress);
        }
    } else {
        std::cout << "❌ Cannot toggle obstacle - invalid conditions:" << std::endl;
        if (x < 0 || x >= m_gridSize || y < 0 || y >= m_gridSize) 
            std::cout << "  - Coordinates out of bounds" << std::endl;
        if (x == m_start.x() && y == m_start.y()) 
            std::cout << "  - Cell is start position" << std::endl;
        if (x == m_end.x() && y == m_end.y()) 
            std::cout << "  - Cell is end position" << std::endl;
    }
    std::cout << "=== TOGGLE OBSTACLE FINISHED ===" << std::endl;
}

void Pathfinder::stepForward() {
    if (m_progress < m_maxProgress) {
        setProgress(m_progress + 1);
    } else {
        // 如果当前进度已经是最大值，但算法还没完成，执行一步算法
        bool anyProgress = false;
        
        if (!m_dijkstraState.finished) {
            anyProgress |= stepAlgorithm(m_dijkstraState, [](int, int, int, int) { return 0; }, true);
        }
        
        if (!m_greedyState.finished) {
            anyProgress |= stepAlgorithm(m_greedyState, [this](int x1, int y1, int x2, int y2) { 
                return heuristic(x1, y1, x2, y2); 
            }, false);
        }
        
        if (!m_aStarState.finished) {
            anyProgress |= stepAlgorithm(m_aStarState, [this](int x1, int y1, int x2, int y2) { 
                return heuristic(x1, y1, x2, y2); 
            }, true);
        }
        
        if (anyProgress) {
            m_maxProgress++;
            emit maxProgressChanged();
            setProgress(m_progress + 1);
        }
    }
}

void Pathfinder::stepBackward() {
    if (m_progress > 0) {
        setProgress(m_progress - 1);
    }
}

void Pathfinder::startSimulation() {
    if (!m_isRunning && m_progress < m_maxProgress) {
        m_isRunning = true;
        emit isRunningChanged();
        m_simulationTimer->start(100);
    }
}

void Pathfinder::stopSimulation() {
    if (m_isRunning) {
        m_isRunning = false;
        emit isRunningChanged();
        m_simulationTimer->stop();
    }
}

void Pathfinder::resetSimulation() {
    std::cout << "Resetting simulation..." << std::endl;
    std::cout << "Current needsRecomputation: " << m_needsRecomputation << std::endl;
    
    stopSimulation();
    m_progress = 0;
    
    if (m_needsRecomputation) {
        std::cout << "Recomputation needed, recomputing algorithms..." << std::endl;
        recomputeAllAlgorithms();
    } else {
        std::cout << "No recomputation needed, just resetting progress." << std::endl;
        emit progressChanged();
        emit gridChanged();
    }
    
    std::cout << "Simulation reset to progress 0" << std::endl;
    std::cout << "Needs recomputation after reset: " << m_needsRecomputation << std::endl;
}

void Pathfinder::clearAllObstacles() {
    std::cout << "=== CLEAR ALL OBSTACLES CALLED ===" << std::endl;
    
    // 移除进度限制
    for (int y = 0; y < m_gridSize; ++y) {
        for (int x = 0; x < m_gridSize; ++x) {
            m_obstacles[y][x] = false;
        }
    }
    
    m_needsRecomputation = true;
    
    // 保存当前进度
    int oldProgress = m_progress;
    
    recomputeAllAlgorithms();
    
    // 如果旧进度大于新最大进度，跳到最后一步
    if (oldProgress > m_maxProgress) {
        setProgress(m_maxProgress);
    } else {
        setProgress(oldProgress);
    }
    
    std::cout << "✅ All obstacles cleared" << std::endl;
}

void Pathfinder::debugPrintGrids() {
    std::cout << "\n=== DEBUG GRID STATE ===" << std::endl;
    std::cout << "Progress: " << m_progress << "/" << m_maxProgress << std::endl;
    std::cout << "Start: (" << m_start.x() << "," << m_start.y() << ")" << std::endl;
    std::cout << "End: (" << m_end.x() << "," << m_end.y() << ")" << std::endl;
    std::cout << "Needs recomputation: " << m_needsRecomputation << std::endl;
    
    std::cout << "\n--- Current QML Data ---" << std::endl;
    std::cout << "Dijkstra data available: " << (m_progress < m_dijkstraState.stepGrids.size()) 
              << " (progress " << m_progress << " < " << m_dijkstraState.stepGrids.size() << ")" << std::endl;
    std::cout << "Greedy data available: " << (m_progress < m_greedyState.stepGrids.size()) 
              << " (progress " << m_progress << " < " << m_greedyState.stepGrids.size() << ")" << std::endl;
    std::cout << "A* data available: " << (m_progress < m_aStarState.stepGrids.size()) 
              << " (progress " << m_progress << " < " << m_aStarState.stepGrids.size() << ")" << std::endl;
    
    if (m_progress < m_dijkstraState.stepGrids.size()) {
        std::cout << "\n--- Dijkstra Internal ---" << std::endl;
        debugPrintGrid("Dijkstra", m_dijkstraState.stepGrids[m_progress], 
                      m_progress < m_dijkstraState.stepPaths.size() ? 
                      m_dijkstraState.stepPaths[m_progress] : QVector<QPoint>());
    }
    
    if (m_progress < m_greedyState.stepGrids.size()) {
        std::cout << "\n--- Greedy Internal ---" << std::endl;
        debugPrintGrid("Greedy", m_greedyState.stepGrids[m_progress],
                      m_progress < m_greedyState.stepPaths.size() ?
                      m_greedyState.stepPaths[m_progress] : QVector<QPoint>());
    }
    
    if (m_progress < m_aStarState.stepGrids.size()) {
        std::cout << "\n--- A* Internal ---" << std::endl;
        debugPrintGrid("A*", m_aStarState.stepGrids[m_progress],
                      m_progress < m_aStarState.stepPaths.size() ?
                      m_aStarState.stepPaths[m_progress] : QVector<QPoint>());
    }
    
    std::cout << "\n--- Algorithm State ---" << std::endl;
    std::cout << "Dijkstra total steps: " << m_dijkstraState.stepGrids.size() << std::endl;
    std::cout << "Greedy total steps: " << m_greedyState.stepGrids.size() << std::endl;
    std::cout << "A* total steps: " << m_aStarState.stepGrids.size() << std::endl;
    std::cout << "Dijkstra finished: " << m_dijkstraState.finished << std::endl;
    std::cout << "Greedy finished: " << m_greedyState.finished << std::endl;
    std::cout << "A* finished: " << m_aStarState.finished << std::endl;
}

void Pathfinder::debugPrintGrid(const QString& name, const QVector<QVector<Cell>>& grid, const QVector<QPoint>& path) const {
    std::cout << name.toStdString() << " Grid:" << std::endl;
    
    for (int y = 0; y < m_gridSize; ++y) {
        for (int x = 0; x < m_gridSize; ++x) {
            const Cell &cell = grid[y][x];
            
            bool inPath = false;
            for (const QPoint &p : path) {
                if (p.x() == x && p.y() == y) {
                    inPath = true;
                    break;
                }
            }
            
            char symbol = '.';
            if (x == m_start.x() && y == m_start.y()) symbol = 'S';
            else if (x == m_end.x() && y == m_end.y()) symbol = 'E';
            else if (cell.isObstacle) symbol = '#';
            else if (inPath) symbol = '*';
            else if (cell.isOpen) symbol = 'O';
            else if (cell.isClosed) symbol = 'C';
            
            std::cout << symbol << " ";
        }
        std::cout << std::endl;
    }
    
    std::cout << "Legend: S=Start, E=End, #=Wall, *=Path, O=Open, C=Closed, .=Unexplored" << std::endl;
    
    int openCount = 0, closedCount = 0, pathCount = path.size();
    for (int y = 0; y < m_gridSize; ++y) {
        for (int x = 0; x < m_gridSize; ++x) {
            const Cell &cell = grid[y][x];
            if (cell.isOpen) openCount++;
            if (cell.isClosed) closedCount++;
        }
    }
    
    std::cout << "Stats: Open=" << openCount << ", Closed=" << closedCount << ", Path=" << pathCount << std::endl;
}

QVector<QVector<Pathfinder::Cell>> Pathfinder::deepCopyGrid(const QVector<QVector<Cell>>& source) const {
    QVector<QVector<Cell>> copy;
    copy.resize(m_gridSize);
    
    for (int y = 0; y < m_gridSize; ++y) {
        copy[y].resize(m_gridSize);
        for (int x = 0; x < m_gridSize; ++x) {
            copy[y][x] = Cell(source[y][x]);
        }
    }
    
    return copy;
}

void Pathfinder::initializeGrids() {
    std::cout << "=== INITIALIZING GRIDS ===" << std::endl;
    
    // 完全重置所有状态
    m_dijkstraState = AlgorithmState([](Cell* a, Cell* b) { return a->g > b->g; });
    m_greedyState = AlgorithmState([](Cell* a, Cell* b) { return a->h > b->h; });
    m_aStarState = AlgorithmState([](Cell* a, Cell* b) { return a->f > b->f; });
    
    m_dijkstraState.grid.resize(m_gridSize);
    m_greedyState.grid.resize(m_gridSize);
    m_aStarState.grid.resize(m_gridSize);
    
    for (int y = 0; y < m_gridSize; ++y) {
        m_dijkstraState.grid[y].resize(m_gridSize);
        m_greedyState.grid[y].resize(m_gridSize);
        m_aStarState.grid[y].resize(m_gridSize);
        
        for (int x = 0; x < m_gridSize; ++x) {
            bool isObstacle = m_obstacles[y][x];
            
            // 完全重置所有单元格
            m_dijkstraState.grid[y][x] = Cell();
            m_dijkstraState.grid[y][x].x = x;
            m_dijkstraState.grid[y][x].y = y;
            m_dijkstraState.grid[y][x].isObstacle = isObstacle;
            m_dijkstraState.grid[y][x].g = INT_MAX;
            m_dijkstraState.grid[y][x].h = 0;
            m_dijkstraState.grid[y][x].f = INT_MAX;
            m_dijkstraState.grid[y][x].isOpen = false;
            m_dijkstraState.grid[y][x].isClosed = false;
            m_dijkstraState.grid[y][x].parent = nullptr;
            
            m_greedyState.grid[y][x] = Cell();
            m_greedyState.grid[y][x].x = x;
            m_greedyState.grid[y][x].y = y;
            m_greedyState.grid[y][x].isObstacle = isObstacle;
            m_greedyState.grid[y][x].g = INT_MAX;
            m_greedyState.grid[y][x].h = 0;
            m_greedyState.grid[y][x].f = INT_MAX;
            m_greedyState.grid[y][x].isOpen = false;
            m_greedyState.grid[y][x].isClosed = false;
            m_greedyState.grid[y][x].parent = nullptr;
            
            m_aStarState.grid[y][x] = Cell();
            m_aStarState.grid[y][x].x = x;
            m_aStarState.grid[y][x].y = y;
            m_aStarState.grid[y][x].isObstacle = isObstacle;
            m_aStarState.grid[y][x].g = INT_MAX;
            m_aStarState.grid[y][x].h = 0;
            m_aStarState.grid[y][x].f = INT_MAX;
            m_aStarState.grid[y][x].isOpen = false;
            m_aStarState.grid[y][x].isClosed = false;
            m_aStarState.grid[y][x].parent = nullptr;
        }
    }
    
    // 清空开放集合
    while (!m_dijkstraState.openSet.empty()) m_dijkstraState.openSet.pop();
    while (!m_greedyState.openSet.empty()) m_greedyState.openSet.pop();
    while (!m_aStarState.openSet.empty()) m_aStarState.openSet.pop();
    
    // 清空路径和步骤
    m_dijkstraState.finalPath.clear();
    m_dijkstraState.stepGrids.clear();
    m_dijkstraState.stepPaths.clear();
    m_dijkstraState.stepFinalPaths.clear();
    m_greedyState.finalPath.clear();
    m_greedyState.stepGrids.clear();
    m_greedyState.stepPaths.clear();
    m_greedyState.stepFinalPaths.clear();
    m_aStarState.finalPath.clear();
    m_aStarState.stepGrids.clear();
    m_aStarState.stepPaths.clear();
    m_aStarState.stepFinalPaths.clear();
    
    m_dijkstraState.finished = false;
    m_greedyState.finished = false;
    m_aStarState.finished = false;
    
    // 设置起点
    Cell* startCell = getCell(m_dijkstraState.grid, m_start.x(), m_start.y());
    if (startCell && !startCell->isObstacle) {
        startCell->g = 0;
        startCell->h = heuristic(startCell->x, startCell->y, m_end.x(), m_end.y());
        startCell->f = startCell->g + startCell->h;
        startCell->isOpen = true;
        m_dijkstraState.openSet.push(startCell);
        std::cout << "Dijkstra start cell initialized at (" << m_start.x() << "," << m_start.y() << ")" << std::endl;
    }
    
    startCell = getCell(m_greedyState.grid, m_start.x(), m_start.y());
    if (startCell && !startCell->isObstacle) {
        startCell->g = 0;
        startCell->h = heuristic(startCell->x, startCell->y, m_end.x(), m_end.y());
        startCell->f = startCell->g + startCell->h;
        startCell->isOpen = true;
        m_greedyState.openSet.push(startCell);
        std::cout << "Greedy start cell initialized at (" << m_start.x() << "," << m_start.y() << ")" << std::endl;
    }
    
    startCell = getCell(m_aStarState.grid, m_start.x(), m_start.y());
    if (startCell && !startCell->isObstacle) {
        startCell->g = 0;
        startCell->h = heuristic(startCell->x, startCell->y, m_end.x(), m_end.y());
        startCell->f = startCell->g + startCell->h;
        startCell->isOpen = true;
        m_aStarState.openSet.push(startCell);
        std::cout << "A* start cell initialized at (" << m_start.x() << "," << m_start.y() << ")" << std::endl;
    }
    
    // 记录初始状态
    m_dijkstraState.stepGrids.append(deepCopyGrid(m_dijkstraState.grid));
    m_greedyState.stepGrids.append(deepCopyGrid(m_greedyState.grid));
    m_aStarState.stepGrids.append(deepCopyGrid(m_aStarState.grid));
    
    std::cout << "All grids initialized. Initial steps recorded." << std::endl;
    std::cout << "Dijkstra open set size: " << m_dijkstraState.openSet.size() << std::endl;
    std::cout << "Greedy open set size: " << m_greedyState.openSet.size() << std::endl;
    std::cout << "A* open set size: " << m_aStarState.openSet.size() << std::endl;
}

void Pathfinder::recomputeAllAlgorithms() {
    std::cout << "\n*** RECOMPUTING ALL ALGORITHMS ***" << std::endl;
    
    // 完全重置所有状态
    initializeGrids();
    
    std::cout << "Computing Dijkstra..." << std::endl;
    computeAlgorithm(m_dijkstraState, [](int, int, int, int) { return 0; }, true);
    
    std::cout << "Computing Greedy..." << std::endl;
    computeAlgorithm(m_greedyState, [this](int x1, int y1, int x2, int y2) { 
        return heuristic(x1, y1, x2, y2); 
    }, false);
    
    std::cout << "Computing A*..." << std::endl;
    computeAlgorithm(m_aStarState, [this](int x1, int y1, int x2, int y2) { 
        return heuristic(x1, y1, x2, y2); 
    }, true);
    
    // 修复：更新最大进度 - 使用三个算法中最大的步骤数
    int dijkstraSteps = m_dijkstraState.stepGrids.size();
    int greedySteps = m_greedyState.stepGrids.size();
    int aStarSteps = m_aStarState.stepGrids.size();
    
    m_maxProgress = qMax(dijkstraSteps, qMax(greedySteps, aStarSteps)) - 1;
    if (m_maxProgress < 0) m_maxProgress = 0;
    
    // 修复：重新计算后总是重置进度为0
    m_progress = 0;
    
    // 重置需要重新计算的标志
    m_needsRecomputation = false;
    
    std::cout << "Recomputation finished." << std::endl;
    std::cout << "Dijkstra steps: " << dijkstraSteps << std::endl;
    std::cout << "Greedy steps: " << greedySteps << std::endl;
    std::cout << "A* steps: " << aStarSteps << std::endl;
    std::cout << "Max progress: " << m_maxProgress << std::endl;
    std::cout << "Current progress: " << m_progress << std::endl;
    
    emit maxProgressChanged();
    emit progressChanged();
    emit gridChanged();
}

void Pathfinder::computeAlgorithm(AlgorithmState& state, const std::function<int(int, int, int, int)>& heuristicFunc, bool useG) {
    std::cout << "=== ENTERING computeAlgorithm ===" << std::endl;
    std::cout << "Algorithm type: " << (useG ? (heuristicFunc(0,0,0,0)==0 ? "Dijkstra" : "A*") : "Greedy") << std::endl;
    
    // 修复：使用合理的最大步数
    int maxSteps = m_gridSize * m_gridSize * 2;  // 增加最大步数限制
    int stepCount = 0;
    
    // 主要算法循环
    while (!state.openSet.empty() && !state.finished && stepCount < maxSteps) {
        stepCount++;
        
        Cell* current = state.openSet.top();
        state.openSet.pop();
        
        // 将当前节点标记为已关闭
        current->isOpen = false;
        current->isClosed = true;
        
        // 如果到达终点
        if (current->x == m_end.x() && current->y == m_end.y()) {
            std::cout << "*** FOUND PATH TO END! ***" << std::endl;
            reconstructPath(state, current);
            state.finished = true;
            
            // 记录最终状态
            state.stepGrids.append(deepCopyGrid(state.grid));
            std::cout << "Final state recorded at step " << state.stepGrids.size() << std::endl;
            break;
        }
        
        // 检查相邻节点
        for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
                if (dx != 0 && dy != 0) continue; // 禁止对角线
                if (dx == 0 && dy == 0) continue;
                
                int nx = current->x + dx;
                int ny = current->y + dy;
                
                if (nx < 0 || nx >= m_gridSize || ny < 0 || ny >= m_gridSize) continue;
                
                Cell* neighbor = getCell(state.grid, nx, ny);
                if (!neighbor) continue;
                
                // 跳过障碍物和已关闭的节点
                if (neighbor->isObstacle || neighbor->isClosed) {
                    continue;
                }
                
                // 计算新的g值
                int tentativeG = current->g + 1;
                
                // 如果新路径更好，更新邻居节点
                if (tentativeG < neighbor->g) {
                    neighbor->parent = current;
                    neighbor->g = tentativeG;
                    neighbor->h = heuristicFunc(neighbor->x, neighbor->y, m_end.x(), m_end.y());
                    neighbor->f = useG ? neighbor->g + neighbor->h : neighbor->h;
                    
                    if (!neighbor->isOpen) {
                        neighbor->isOpen = true;
                        state.openSet.push(neighbor);
                    }
                }
            }
        }
        
        // 记录当前步骤状态
        state.stepGrids.append(deepCopyGrid(state.grid));
    }
    
    // 如果算法没有找到路径但已经完成，也要确保状态一致
    if (!state.finished) {
        std::cout << "Algorithm stopped after " << stepCount << " steps without finding path" << std::endl;
        // 如果没有找到路径，也要记录最终状态
        state.stepGrids.append(deepCopyGrid(state.grid));
    }
    
    std::cout << "Total recorded steps: " << state.stepGrids.size() << std::endl;
}

bool Pathfinder::stepAlgorithm(AlgorithmState& state, const std::function<int(int, int, int, int)>& heuristicFunc, bool useG) {
    if (state.finished || state.openSet.empty()) {
        return false;
    }
    
    // 从开放集合中获取下一个单元格
    Cell* current = state.openSet.top();
    state.openSet.pop();
    
    std::cout << "Processing cell (" << current->x << "," << current->y << ") g=" << current->g << std::endl;
    
    // 将当前节点标记为已关闭
    current->isOpen = false;
    current->isClosed = true;
    
    // 如果到达终点
    if (current->x == m_end.x() && current->y == m_end.y()) {
        std::cout << "*** FOUND PATH TO END! ***" << std::endl;
        reconstructPath(state, current);
        state.finished = true;
        
        // 记录最终状态
        state.stepGrids.append(deepCopyGrid(state.grid));
        return true;
    }
    
    // 检查邻居
    for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
            if (dx != 0 && dy != 0) continue; // 禁止对角线
            if (dx == 0 && dy == 0) continue;
            
            int nx = current->x + dx;
            int ny = current->y + dy;
            
            if (nx < 0 || nx >= m_gridSize || ny < 0 || ny >= m_gridSize) continue;
            
            Cell* neighbor = getCell(state.grid, nx, ny);
            if (!neighbor) continue;
            
            // 跳过障碍物和已关闭的节点
            if (neighbor->isObstacle || neighbor->isClosed) {
                continue;
            }
            
            // 计算新的g值
            int tentativeG = current->g + 1;
            
            // 如果新路径更好，更新邻居节点
            if (tentativeG < neighbor->g) {
                neighbor->parent = current;
                neighbor->g = tentativeG;
                neighbor->h = heuristicFunc(neighbor->x, neighbor->y, m_end.x(), m_end.y());
                neighbor->f = useG ? neighbor->g + neighbor->h : neighbor->h;
                
                if (!neighbor->isOpen) {
                    neighbor->isOpen = true;
                    state.openSet.push(neighbor);
                }
            }
        }
    }
    
    // 记录当前步骤状态
    state.stepGrids.append(deepCopyGrid(state.grid));
    
    return true;
}

int Pathfinder::heuristic(int x1, int y1, int x2, int y2) {
    return qAbs(x1 - x2) + qAbs(y1 - y2);
}

// 修改：重构路径函数，确保在找到终点时立即保存最终路径
void Pathfinder::reconstructPath(AlgorithmState &state, Cell *current) {
    // 如果是到达终点，保存最终路径
    if (current->x == m_end.x() && current->y == m_end.y()) {
        state.finalPath.clear();
        Cell* temp = current;
        while (temp) {
            state.finalPath.prepend(QPoint(temp->x, temp->y));
            temp = temp->parent;
        }
        std::cout << "Final path reconstructed, length: " << state.finalPath.size() << std::endl;
        
        // 立即发射信号更新显示
        emit gridChanged();
    }
}

// 简化：只保留最终路径参数
QVariantMap Pathfinder::cellToVariantMap(const Cell& cell, bool inFinalPath) const {
    QVariantMap cellData;
    cellData["x"] = cell.x;
    cellData["y"] = cell.y;
    cellData["isObstacle"] = cell.isObstacle;
    cellData["g"] = cell.g == INT_MAX ? 999 : cell.g;
    cellData["h"] = cell.h;
    cellData["f"] = cell.f == INT_MAX ? 999 : cell.f;
    cellData["isOpen"] = cell.isOpen;
    cellData["isClosed"] = cell.isClosed;
    cellData["isFinalPath"] = inFinalPath;  // 只保留最终路径
    return cellData;
}

// 修改 getDijkstraCell 方法，确保显示当前步骤的状态
QVariantMap Pathfinder::getDijkstraCell(int x, int y) const {
    if (x < 0 || x >= m_gridSize || y < 0 || y >= m_gridSize) {
        return QVariantMap();
    }
    
    // 修复：始终显示当前进度的状态，而不是最终状态
    int displayProgress = qMin(m_progress, m_dijkstraState.stepGrids.size() - 1);
    
    if (displayProgress >= 0 && displayProgress < m_dijkstraState.stepGrids.size()) {
        const auto& grid = m_dijkstraState.stepGrids[displayProgress];
        
        // 检查是否在最终路径中 - 只有在算法完成且是最后一步时才显示
        bool inFinalPath = false;
        if (m_dijkstraState.finished && displayProgress == (m_dijkstraState.stepGrids.size() - 1)) {
            for (const QPoint &p : m_dijkstraState.finalPath) {
                if (p.x() == x && p.y() == y) {
                    inFinalPath = true;
                    break;
                }
            }
        }
        
        return cellToVariantMap(grid[y][x], inFinalPath);
    }
    
    // 默认数据
    return createDefaultCellData(x, y);
}

// 同样修改 getGreedyCell 方法
QVariantMap Pathfinder::getGreedyCell(int x, int y) const {
    if (x < 0 || x >= m_gridSize || y < 0 || y >= m_gridSize) {
        return QVariantMap();
    }
    
    // 修复：始终显示当前进度的状态
    int displayProgress = qMin(m_progress, m_greedyState.stepGrids.size() - 1);
    
    if (displayProgress >= 0 && displayProgress < m_greedyState.stepGrids.size()) {
        const auto& grid = m_greedyState.stepGrids[displayProgress];
        
        bool inFinalPath = false;
        if (m_greedyState.finished && displayProgress == (m_greedyState.stepGrids.size() - 1)) {
            for (const QPoint &p : m_greedyState.finalPath) {
                if (p.x() == x && p.y() == y) {
                    inFinalPath = true;
                    break;
                }
            }
        }
        
        return cellToVariantMap(grid[y][x], inFinalPath);
    }
    
    return createDefaultCellData(x, y);
}

// 同样修改 getAStarCell 方法
QVariantMap Pathfinder::getAStarCell(int x, int y) const {
    if (x < 0 || x >= m_gridSize || y < 0 || y >= m_gridSize) {
        return QVariantMap();
    }
    
    // 修复：始终显示当前进度的状态
    int displayProgress = qMin(m_progress, m_aStarState.stepGrids.size() - 1);
    
    if (displayProgress >= 0 && displayProgress < m_aStarState.stepGrids.size()) {
        const auto& grid = m_aStarState.stepGrids[displayProgress];
        
        bool inFinalPath = false;
        if (m_aStarState.finished && displayProgress == (m_aStarState.stepGrids.size() - 1)) {
            for (const QPoint &p : m_aStarState.finalPath) {
                if (p.x() == x && p.y() == y) {
                    inFinalPath = true;
                    break;
                }
            }
        }
        
        return cellToVariantMap(grid[y][x], inFinalPath);
    }
    
    return createDefaultCellData(x, y);
}

QVariantMap Pathfinder::createDefaultCellData(int x, int y) const {
    QVariantMap defaultData;
    defaultData["x"] = x;
    defaultData["y"] = y;
    defaultData["isObstacle"] = m_obstacles[y][x];
    defaultData["g"] = 999;
    defaultData["h"] = 0;
    defaultData["f"] = 999;
    defaultData["isOpen"] = false;
    defaultData["isClosed"] = false;
    defaultData["isFinalPath"] = false;
    return defaultData;
}

Pathfinder::Cell* Pathfinder::getCell(QVector<QVector<Pathfinder::Cell>>& grid, int x, int y) {
    if (x >= 0 && x < m_gridSize && y >= 0 && y < m_gridSize) {
        return &grid[y][x];
    }
    return nullptr;
}

// 实现 debugStepInfo 方法
void Pathfinder::debugStepInfo() const {
    std::cout << "\n=== STEP DEBUG INFO ===" << std::endl;
    std::cout << "Current progress: " << m_progress << "/" << m_maxProgress << std::endl;
    std::cout << "Dijkstra steps: " << m_dijkstraState.stepGrids.size() 
              << ", finished: " << m_dijkstraState.finished << std::endl;
    std::cout << "Greedy steps: " << m_greedyState.stepGrids.size() 
              << ", finished: " << m_greedyState.finished << std::endl;
    std::cout << "A* steps: " << m_aStarState.stepGrids.size() 
              << ", finished: " << m_aStarState.finished << std::endl;
    
    // 检查特定单元格在不同步骤的状态
    if (m_dijkstraState.stepGrids.size() > 0) {
        std::cout << "Dijkstra start cell at step 0: " 
                  << "g=" << m_dijkstraState.stepGrids[0][m_start.y()][m_start.x()].g 
                  << ", isOpen=" << m_dijkstraState.stepGrids[0][m_start.y()][m_start.x()].isOpen << std::endl;
    }
    if (m_dijkstraState.stepGrids.size() > m_progress) {
        std::cout << "Dijkstra start cell at current step: " 
                  << "g=" << m_dijkstraState.stepGrids[m_progress][m_start.y()][m_start.x()].g 
                  << ", isOpen=" << m_dijkstraState.stepGrids[m_progress][m_start.y()][m_start.x()].isOpen << std::endl;
    }
}