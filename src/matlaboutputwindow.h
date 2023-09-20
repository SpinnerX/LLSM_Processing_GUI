#ifndef MATLABOUTPUTWINDOW_H
#define MATLABOUTPUTWINDOW_H

#include <QDialog>
#include <QThread>
#include <QMessageBox>
#include <QHBoxLayout>
#include <QDesktopServices>
#include <unordered_map>
#include "matlaboutputwindowthread.h"
#include "outputbox.h"

namespace Ui {
class matlabOutputWindow;
}

class matlabOutputWindow : public QDialog
{
    Q_OBJECT

public:
    explicit matlabOutputWindow(std::unordered_map<int,std::pair<QString,QDateTime>> &jobLogPaths, std::unordered_map<int,QString> &jobNames, QWidget *parent = nullptr);
    ~matlabOutputWindow();
public slots:
    void onUpdateOutputForm(std::map<int,std::map<QString,QString>> *fNames, QMutex *fileNamesLock);
private slots:
    void onJobButtonClicked();
protected:
    void closeEvent(QCloseEvent *event) override;

private:
    Ui::matlabOutputWindow *ui;
    matlabOutputWindowThread *mOWThread;
    std::unordered_map<int,std::pair<outputBox,std::unordered_map<QString,QPushButton*>>> buttons;
    std::unordered_map<int,std::pair<QString,QDateTime>> *jobLogPaths;
    std::unordered_map<int,QString> *jobNames;
    outputBox mainBox;
};

#endif // MATLABOUTPUTWINDOW_H
