#ifndef PATHFINDER_H
#define PATHFINDER_H

#include <QObject>
#include <QVector>
#include <QPoint>
#include <QTimer>
#include <QVariantMap> // 添加QVariantMap的包含
#include <queue> // 添加priority_queue所需的头文件
#include <functional> // 添加std::function所需头文件

class Pathfinder : public QObject {
    Q_OBJECT
    Q_PROPERTY(int gridSize READ gridSize WRITE setGridSize NOTIFY gridSizeChanged)
    Q_PROPERTY(QPoint start READ start WRITE setStart NOTIFY startChanged)
    Q_PROPERTY(QPoint end READ end WRITE setEnd NOTIFY endChanged)
    Q_PROPERTY(QVariantList grid READ grid NOTIFY gridChanged)

public:
    explicit Pathfinder(QObject *parent = nullptr);

    int gridSize() const;
    void setGridSize(int size);

    QPoint start() const;
    void setStart(const QPoint &point);

    QPoint end() const;
    void setEnd(const QPoint &point);

    QVariantList grid() const;

    Q_INVOKABLE void toggleObstacle(int x, int y);
    Q_INVOKABLE void findPath();
    Q_INVOKABLE bool isInPath(int x, int y) const;

signals:
    void gridSizeChanged();
    void startChanged();
    void endChanged();
    void gridChanged();

private:
    struct Cell {
        int x, y;
        bool isObstacle;
        int g;
        int h;
        int f;
        bool isOpen;
        bool isClosed;
        Cell *parent;
    };

    QVector<QVector<Cell>> m_grid;
    int m_gridSize;
    QPoint m_start;
    QPoint m_end;
    QTimer *m_timer;
    QVector<QPoint> m_path;

    void initializeGrid();
    int heuristic(int x1, int y1, int x2, int y2); // 修复了缺少分号的问题
    void reconstructPath(Cell *current);
    void stepAStar();
};

#endif // PATHFINDER_H