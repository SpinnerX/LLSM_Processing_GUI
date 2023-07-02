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

/**
 * @brief 
 * Idea for this class is to have features like the following or similar:
 * 
 * mainwindowConsoleOutputWindow.h
 * 
 * mainwindowConsoleOutputWindow* consoleWindow = new consoleWindow(QStirng("Matlab Output Window"), this);
 * consoleWindow.logMessage("This is a testing mesesage!");
 * 
 * For right now just to grab logs, and let this be utilized to show output on this window throughout the codebase.
 * Allows for flexbility uses.
 * 
 * 
 * This class is what creates the side window.
 * Which we can use throughout the codebase, if we ever want other code to simply call this header
*/

class mainwindowConsoleOutputWindow : public QDockWidget{
public:
    mainwindowConsoleOutputWindow() = default;
    mainwindowConsoleOutputWindow(const QString&& title,QMutex& outputLock, QWidget* parent=nullptr);
    ~mainwindowConsoleOutputWindow();

    void uploadJobLogs(matlabOutputWindow *jobLogsOutputWindow);

    /**
     * @brief 
     * 
     * This just allows us to print logging from stdout and stderr onto the QDockWidget
     * 
     * @param msg 
     * @param delimeter 
     */
    void printLog(QString msg, char delimeter='\n');
    void printLogStdString(std::string msg, char delimeter='\n');
    void printLogStream(std::stringstream stream, char delimieter='\n');

public slots:
    void updateTimer();

private:
    QTextEdit* consoleEdit;
    QMutex* outputLock;
    std::stringstream buffer;
    QTimer* timer;
    std::vector<QBuffer *> buffers;
};

