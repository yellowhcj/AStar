#include <QtQuickControls2/QQuickStyle>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include "pathfinder.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    qmlRegisterType<Pathfinder>("AStar", 1, 0, "Pathfinder");
    QQuickStyle::setStyle("Fusion");
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }
    return app.exec();
}