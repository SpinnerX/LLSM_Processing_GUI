#ifndef MATLABTHREADMANAGER_H
#define MATLABTHREADMANAGER_H

//#include "MatlabEngine.hpp"
//#include "MatlabDataArray.hpp"
#include "matlabthread.h"
#include <unordered_map>
#include <QtCore>
#include <QThread>
#include "mainwindowConsoleOutputWindow.h"
//using namespace matlab::engine;

class matlabThreadManager : public QThread
{
    Q_OBJECT
public:
    matlabThreadManager(QMutex &outputLock, QObject *parent = 0);
    ~matlabThreadManager();
    void killMatlabThreadManager();
    std::string str();
    void run();
public slots:
    void onJobStart(std::string &args, QString &funcType, std::tuple<QString, QString, bool> &mPathJNameParseCluster, std::unordered_map<int,std::pair<QString,QDateTime>> &jobLogPaths, bool isMcc, const std::string &pathToMatlab);
    void onProcessOutputSignal(QByteArray data);
signals:
    void enableSubmitButton();
    // void availableOutput(QString output);
    void availableOutput(QString str);
private:
    std::string args;
    std::unordered_map<unsigned int, matlabThread*> mThreads;
    //std::unique_ptr<MATLABEngine> matlabPtr;
    //matlab::data::ArrayFactory factory;
    QMutex *outputLock;
    std::tuple<QString, QString, bool> mPathJNameParseCluster;
    std::unordered_map<int,std::pair<QString,QDateTime>> *jobLogPaths;
    size_t outA;
    //std::vector<matlab::data::Array> data;
    QString funcType;
    bool isMcc;
    std::string pathToMatlab;

    bool killThread;
    std::ostringstream jobsOutput;
    std::streambuf* old;
    std::vector<QProcess *> processors;
    std::vector<std::string> commands; // commands to execute script.
    std::vector<std::vector<QString> > childThreadsOutput; // This contains output from each thread.
};

#endif // MATLABTHREADMANAGER_H
