#include "mainwindowConsoleOutputWindow.h"
#include <QTextStream>
#include <fstream>
#include <array>

mainwindowConsoleOutputWindow::mainwindowConsoleOutputWindow(const QString&& title, QMutex& outputLock, QWidget* parent) 
        : QDockWidget(parent),
          outputLock(&outputLock){
    
    setWindowTitle(title);
    consoleEdit = new QTextEdit(this);
    timer = new QTimer(this);
    setWidget(consoleEdit);

    connect(timer, SIGNAL(timeout()), this, SLOT(updateTimer)); // this basically allows us to setup the QTimer.
    
    timer->setInterval(2000); // every 2 seconds we print out this onto the QDockWidget
    timer->start();
}

mainwindowConsoleOutputWindow::~mainwindowConsoleOutputWindow(){
    delete consoleEdit;
}

void mainwindowConsoleOutputWindow::printLog(QString msg, char delimeter){
    outputLock->lock();
    consoleEdit->append(msg + delimeter);
    outputLock->unlock();
}

void mainwindowConsoleOutputWindow::printLogStdString(std::string msg, char delimeter){
    outputLock->lock();
    QString str = QString::fromUtf8(msg);
    consoleEdit->append(str);
    outputLock->unlock();
}

void mainwindowConsoleOutputWindow::printLogStream(std::stringstream stream, char delimieter){
    outputLock->lock();
    QString str = QString::fromUtf8(stream.str());
    consoleEdit->append(str);

    outputLock->unlock();
}

// This is where we add the jobs to the QDockWidget
void mainwindowConsoleOutputWindow::uploadJobLogs(matlabOutputWindow *jobLogsOutputWindow){
    this->setWidget(jobLogsOutputWindow);

    if(!jobLogsOutputWindow->isVisible()){
        jobLogsOutputWindow->setModal(false);
        jobLogsOutputWindow->show();
    }
}

void mainwindowConsoleOutputWindow::updateTimer(){
    outputLock->lock();
    /**
     * @brief 
     * 
     * Loop through all the differnt buffers, and output from them if the are on a newline, or end of character..
     * 
     * And we do this in here, as this function will be called every 2 secs.
     while(true){ // Timer acts as the while, now time to do the FOR-LOOP...
		for(auto a : A){
			printOut(a);
			printErr(a);
		}
	}

    Which is essentially doing this...
    // A - can be the current stdout and stderr
    // as well the vector of Buffers that we have..

    function(){
	    for(auto a : A){
		    if(aOut.end() == ‘’\0’){ // Basically checking if the a has reached the end,
			    printOut(a);
		    }
		    if(aErr.end() == ‘\n’){
			    printErr(a);
		    }
	    }
    }
    */

   // for(auto ss : buffers){
    for(QBuffer* buf : buffers){
        // if(*buffers[i]->end() == '\0') printLogStdString(buffers[i]);
        // if(*buffers[i].end() == '\n') printLogStdString(buffers[i]);
        QByteArray data = buf->data();
        // std::cout << data.data() << '\n';
        std::string output = data.data();
        

        QString str = QString::fromUtf8(output);
        consoleEdit->append(str);
   }

   outputLock->unlock();
}
