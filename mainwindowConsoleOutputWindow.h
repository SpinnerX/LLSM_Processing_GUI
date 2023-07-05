#pragma once
#include <QApplication>
#include <QWidget>
#include <QDockWidget>
#include <QPlainTextEdit>
#include <QTextStream>
#include <sstream>
#include <QMutex>
#include <iostream>
#include <vector>
#include <sstream>
#include <QProcess>
#include "matlaboutputwindow.h"
#include <unistd.h>
#include <fcntl.h>
#include <sstream>
#include <QTextBrowser>
#include "matlabthread.h"

class mainwindowConsoleOutputWindow : public QDockWidget{
public:
    mainwindowConsoleOutputWindow() = default;
    mainwindowConsoleOutputWindow(const QString&& title,QMutex& outputLock, QWidget* parent=nullptr);
    ~mainwindowConsoleOutputWindow();

    void uploadJobLogs(matlabOutputWindow *jobLogsOutputWindow);

    void printLog(QString msg, char delimeter='\n');
    void printLogStdString(std::string msg, char delimeter='\n');
    void printLogStream(std::stringstream stream, char delimieter='\n');

public slots:
    void updateTimer();
    void printStdout(QString str);

private:
    // QTextEdit* consoleEdit;
    QTextBrowser* consoleEdit;
    QMutex* outputLock;
    std::stringstream buffer;
    QTimer* timer;
    std::vector<QBuffer *> buffers;
    static int processCounter;
};

