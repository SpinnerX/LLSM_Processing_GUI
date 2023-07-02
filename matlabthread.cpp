#include <iostream>
#include <stdlib.h>
#include <regex>
#include "matlabthread.h"

matlabThread::matlabThread(QObject *parent, const QString &funcType, const size_t &outA, const std::string &args, std::tuple<QString, QString, bool> &mPathJNameParseCluster, const unsigned int &mThreadID, bool isMcc, const std::string &pathToMatlab) :
    QThread(parent), funcType(funcType), outA(outA), args(args), mPathJNameParseCluster(mPathJNameParseCluster), mThreadID(mThreadID), isMcc(isMcc), pathToMatlab(pathToMatlab)
{
    job = nullptr;
    killThread = 0;
}

matlabThread::~matlabThread(){
    /*
    if(mOutThread){
        if(!mOutThread->isFinished()) {
            mOutThread->terminate();
        }
    }
    */
    if(job){
        job->kill();
        job->terminate();
    }
    killThread = 1;
}

void matlabThread::killMatlabThread(){
    killThread = 1;
}

void matlabThread::run(){
    // Start matlab and add needed paths
    bool jobSuccess = true;

    std::string matlabCmd;

    // If the user has a matlab installation
    if(!isMcc){
        std::string matlabOptions = "-batch";
        matlabCmd.append("\""+pathToMatlab+"\" "+matlabOptions);
        //matlab -batch "cd('/clusterfs/nvme/matthewmueller/clusterBenchmarking');clusterBenchmarking;exit;"

        // Add the LLSM5DTools Repository to the path
        std::string newDir = QCoreApplication::applicationDirPath().toStdString()+"/LLSM5DTools";
        matlabCmd.append(" \"cd(\'"+newDir+"\');");
        matlabCmd.append("addpath(genpath(\'"+newDir+"\'));");

        // Add the setup cmd
        matlabCmd.append("setup;");

        matlabCmd.append(funcType.toStdString()+"("+args+");");
        matlabCmd.append("\"");
    }
    // If the user is using mcc
    else{
        #ifdef __linux__
        std::string mccLoc = "\""+QCoreApplication::applicationDirPath().toStdString()+"/LLSM5DTools/mcc/linux/run_mccMaster.sh\"";
        #elif _WIN32
        std::string mccLoc = "\""+QCoreApplication::applicationDirPath().toStdString()+"/LLSM5DTools/mcc/windows/mccMaster\"";
        #else
        std::string mccLoc = "";
        #endif
        matlabCmd.append(mccLoc);

        #ifndef _WIN32
        matlabCmd.append(" \""+pathToMatlab+"\"");
        #endif
        matlabCmd.append(" "+funcType.toStdString()+" "+args);
        // Replace all instances of "" with """""" to conform with QProcess
        // Later we can change the setup functions to account for this
        matlabCmd = std::regex_replace(matlabCmd, std::regex(" \"\""), " \"\"\"\"\"\"");
    }

    //std::cout << matlabCmd << std::endl;
    //jobSuccess = !system(matlabCmd.c_str());
    job = new QProcess(this);
    job->startCommand(QString::fromStdString(matlabCmd));
    job->setProcessChannelMode(QProcess::ForwardedChannels);
    job->waitForFinished(-1);

    // QString outStr = QString(job->readAllStandardOutput());
    // QString errStr = QString(job->readAllStandardError());
    // std::cout << outStr.toStdString() << '\n';
    // std::cout << errStr.toStdString() << '\n';
    std::cout << QString(job->readAllStandardOutput()).toStdString() << '\n';
    std::cout << QString(job->readAllStandardError()).toStdString() << '\n';
    jobSuccess = !(job->exitCode());


    if(jobSuccess) std::cout << "Matlab Job \"" << std::get<1>(mPathJNameParseCluster).toStdString() << "\" Finished" << std::endl;
    else{
        //if(std::get<2>(mPathJNameParseCluster))
        std::cout << "Matlab Job \"" << std::get<1>(mPathJNameParseCluster).toStdString() << "\" has Failed. MATLAB EXCEPTION." << std::endl;
        //else std::cout << "Matlab Job \"" << std::get<1>(mPathJNameParseCluster).toStdString() << "\" has Failed. MATLAB EXCEPTION. Check job output file for details." << std::endl;
    }
}

