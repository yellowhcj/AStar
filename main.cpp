#include <QtQuickControls2/QQuickStyle>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QIcon>
#include "pathfinder.h"

int main(int argc, char *argv[]) {
    QGuiApplication app(argc, argv);
    
    // 设置应用程序图标
    app.setWindowIcon(QIcon(":/logo.ico"));  // 从资源文件加载
    
    qmlRegisterType<Pathfinder>("AStar", 1, 0, "Pathfinder");
    QQuickStyle::setStyle("Fusion");
    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }
    return app.exec();
}