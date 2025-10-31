#ifndef PATHFINDER_H
#define PATHFINDER_H

#include <QObject>
#include <QVector>
#include <QPoint>
#include <QTimer>
#include <QVariantMap>
#include <queue>
#include <functional>

class Pathfinder : public QObject {
    Q_OBJECT
    Q_PROPERTY(int gridSize READ gridSize WRITE setGridSize NOTIFY gridSizeChanged)
    Q_PROPERTY(QPoint start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(QPoint end READ end WRITE setEnd NOTIFY endChanged)
    Q_PROPERTY(int progress READ progress WRITE setProgress NOTIFY progressChanged)
    Q_PROPERTY(int maxProgress READ maxProgress NOTIFY maxProgressChanged)
    Q_PROPERTY(bool isRunning READ isRunning NOTIFY isRunningChanged)

public:
    explicit Pathfinder(QObject *parent = nullptr);

    int gridSize() const;
    void setGridSize(int size);

    QPoint start() const;
    void setStart(const QPoint &point);

    QPoint end() const;
    void setEnd(const QPoint &point);

    int progress() const;
    void setProgress(int progress);
    
    int maxProgress() const;
    
    bool isRunning() const;

    Q_INVOKABLE void toggleObstacle(int x, int y);
    Q_INVOKABLE void stepForward();
    Q_INVOKABLE void stepBackward();
    Q_INVOKABLE void startSimulation();
    Q_INVOKABLE void stopSimulation();
    Q_INVOKABLE void resetSimulation();
    Q_INVOKABLE void debugPrintGrids();
    Q_INVOKABLE void clearAllObstacles();
    
    // 直接获取单元格数据的函数
    Q_INVOKABLE QVariantMap getDijkstraCell(int x, int y) const;
    Q_INVOKABLE QVariantMap getGreedyCell(int x, int y) const;
    Q_INVOKABLE QVariantMap getAStarCell(int x, int y) const;
    
    // 添加调试方法
    Q_INVOKABLE void debugStepInfo() const;

signals:
    void gridSizeChanged();
    void startChanged();
    void endChanged();
    void progressChanged();
    void maxProgressChanged();
    void isRunningChanged();
    void gridChanged();

private:
    struct Cell {
        int x, y;
        bool isObstacle;
        int g, h, f;
        bool isOpen, isClosed;
        Cell *parent;
        
        Cell() : x(0), y(0), isObstacle(false), g(INT_MAX), h(0), f(INT_MAX), 
                isOpen(false), isClosed(false), parent(nullptr) {}
        
        Cell(const Cell& other) 
            : x(other.x), y(other.y), isObstacle(other.isObstacle), 
              g(other.g), h(other.h), f(other.f),
              isOpen(other.isOpen), isClosed(other.isClosed), parent(other.parent) {}
    };

    struct AlgorithmState {
        QVector<QVector<Cell>> grid;
        std::priority_queue<Cell*, std::vector<Cell*>, std::function<bool(Cell*, Cell*)>> openSet;
        QVector<QPoint> finalPath;  // 最终路径
        bool finished;
        
        QVector<QVector<QVector<Cell>>> stepGrids;
        QVector<QVector<QPoint>> stepPaths;       // 添加缺失的成员
        QVector<QVector<QPoint>> stepFinalPaths;  // 添加缺失的成员
        
        AlgorithmState(std::function<bool(Cell*, Cell*)> cmp) : 
            openSet(cmp), finished(false) {}
    };
    
    void computeAlgorithm(AlgorithmState& state, const std::function<int(int, int, int, int)>& heuristicFunc, bool useG);

    int m_gridSize;
    QPoint m_start;
    QPoint m_end;
    QTimer *m_simulationTimer;
    
    AlgorithmState m_dijkstraState;
    AlgorithmState m_greedyState;
    AlgorithmState m_aStarState;
    
    int m_progress;
    int m_maxProgress;
    bool m_isRunning;
    bool m_needsRecomputation;

    QVector<QVector<bool>> m_obstacles;

    void initializeGrids();
    void recomputeAllAlgorithms();
    
    bool stepAlgorithm(AlgorithmState& state, const std::function<int(int, int, int, int)>& heuristicFunc, bool useG);
    
    int heuristic(int x1, int y1, int x2, int y2);
    void reconstructPath(AlgorithmState &state, Cell *current);
    QVariantMap cellToVariantMap(const Cell& cell, bool inFinalPath) const;  // 简化：只保留最终路径参数
    Cell* getCell(QVector<QVector<Cell>>& grid, int x, int y);
    
    QVector<QVector<Cell>> deepCopyGrid(const QVector<QVector<Cell>>& source) const;
    
    void debugPrintGrid(const QString& name, const QVector<QVector<Cell>>& grid, const QVector<QPoint>& path) const;
    QVariantMap createDefaultCellData(int x, int y) const;
};

#endif // PATHFINDER_H