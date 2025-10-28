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
    Q_PROPERTY(QVariantList dijkstraGrid READ dijkstraGrid NOTIFY gridChanged)
    Q_PROPERTY(QVariantList greedyGrid READ greedyGrid NOTIFY gridChanged)
    Q_PROPERTY(QVariantList aStarGrid READ aStarGrid NOTIFY gridChanged)
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

    QVariantList dijkstraGrid() const;
    QVariantList greedyGrid() const;
    QVariantList aStarGrid() const;

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

signals:
    void gridSizeChanged();
    void startChanged();
    void endChanged();
    void gridChanged();
    void progressChanged();
    void maxProgressChanged();
    void isRunningChanged();

private:
    struct Cell {
        int x, y;
        bool isObstacle;
        int g, h, f;
        bool isOpen, isClosed;
        Cell *parent;
        
        Cell() : x(0), y(0), isObstacle(false), g(0), h(0), f(0), 
                isOpen(false), isClosed(false), parent(nullptr) {}
    };

    struct AlgorithmState {
        QVector<QVector<Cell>> grid;
        std::priority_queue<Cell*, std::vector<Cell*>, std::function<bool(Cell*, Cell*)>> openSet;
        QVector<QPoint> path;
        bool finished;
        
        QVector<QVariantList> stepGrids;
        QVector<QVector<QPoint>> stepPaths;
        
        AlgorithmState(std::function<bool(Cell*, Cell*)> cmp) : 
            openSet(cmp), finished(false) {}
    };

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
    void computeAlgorithm(AlgorithmState& state, const std::function<int(int, int, int, int)>& heuristicFunc, bool useG);
    int getOpenSetSize(AlgorithmState& state);  // 添加函数声明
    int heuristic(int x1, int y1, int x2, int y2);
    void reconstructPath(AlgorithmState &state, Cell *current);
    QVariantList gridToVariantList(const QVector<QVector<Cell>>& grid, const QVector<QPoint>& path) const;
    Cell* getCell(QVector<QVector<Cell>>& grid, int x, int y);
    
    void debugPrintGrid(const QString& name, const QVector<QVector<Cell>>& grid, const QVector<QPoint>& path) const;
};

#endif // PATHFINDER_H