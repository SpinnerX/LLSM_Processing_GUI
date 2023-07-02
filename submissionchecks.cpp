#include "submissionchecks.h"

void messageBoxError(QString errorText){
    QMessageBox messageBox;
    messageBox.warning(0,"Error",errorText);
    messageBox.setFixedSize(500,200);
    return;
}

void messageBoxSuccess(QWidget* parent, QString successText){
    QMessageBox messageBox(parent);
    messageBox.information(0,"Success",successText);
    messageBox.setFixedSize(500,200);
    return;
}

bool pathsFound(dataPath& path){
    if(path.includeMaster){
        if(!QFileInfo::exists(path.masterPath)){
            messageBoxError("Data path \"" + path.masterPath + "\" does not exist!");
            return false;
        }
    }
    for (const auto &subPath : path.subPaths){
        if(subPath.second.first){
            if(!QFileInfo::exists(subPath.second.second)){
                messageBoxError("Data path \"" + subPath.second.second + "\" does not exist!");
                return false;
            }
        }
    }
    
    return true;
}