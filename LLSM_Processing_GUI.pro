######################################################################
# Automatically generated by qmake (3.0) Thu Feb 25 16:11:28 2021
######################################################################
TEMPLATE = app
TARGET = LLSM_Processing_GUI
QT += widgets

CONFIG += c++17

# Input
HEADERS += \
           configfilecreator.h \
           configfilesettings.h \
           datapath.h \
           datapaths.h \
           datapathsrecursive.h \
           deconadvanced.h \
           dsradvanced.h \
           jobadvanced.h \
           jobtext.h \
           jobtextmanager.h \
           largescaleprocessingsettings.h \
           mainadvanced.h \
           mainwindow.h \
           matlabhelperfunctions.h \
           matlaboutputthread.h \
           matlaboutputwindow.h \
           matlaboutputwindowthread.h \
           matlabthread.h \
           matlabthreadmanager.h \
           loadprevioussettings.h \
           outputbox.h \
           simreconjobadvanced.h \
           simreconmainadvanced.h \
           simreconreconadvanced.h \
           submissionchecks.h       \
           mainwindowConsoleOutputWindow.h

FORMS += \
         configfilecreator.ui \
         configfilesettings.ui \
         datapaths.ui \
         datapathsrecursive.ui \
         deconadvanced.ui \
         dsradvanced.ui \
         jobadvanced.ui \
         jobtext.ui \
         largescaleprocessingsettings.ui \
         mainadvanced.ui \
         mainwindow.ui \
         matlaboutputwindow.ui \
         loadprevioussettings.ui \
         simreconjobadvanced.ui \
         simreconmainadvanced.ui \
         simreconreconadvanced.ui

SOURCES += \
           configfilecreator.cpp \
           configfilesettings.cpp \
           datapath.cpp \
           datapaths.cpp \
           datapathsrecursive.cpp \
           deconadvanced.cpp \
           dsradvanced.cpp \
           jobadvanced.cpp \
           jobtext.cpp \
           jobtextmanager.cpp \
           largescaleprocessingsettings.cpp \
           main.cpp \
           mainadvanced.cpp \
           mainwindow.cpp \
           matlabhelperfunctions.cpp \
           matlaboutputthread.cpp \
           matlaboutputwindow.cpp \
           matlaboutputwindowthread.cpp \
           matlabthread.cpp \
           matlabthreadmanager.cpp \
           loadprevioussettings.cpp \
           outputbox.cpp \
           simreconjobadvanced.cpp \
           simreconmainadvanced.cpp \
           simreconreconadvanced.cpp \
           submissionchecks.cpp     \
           mainwindowConsoleOutputWindow.cpp

RESOURCES += \
    resources.qrc

TRANSLATIONS += LLSM_Processing_GUI_en_US.ts

# Remove possible other optimization flags
QMAKE_CXXFLAGS_RELEASE -= -O
QMAKE_CXXFLAGS_RELEASE -= -O1
QMAKE_CXXFLAGS_RELEASE -= -O2

# Add -O3 if not present
QMAKE_CXXFLAGS_RELEASE *= -O3

unix:!macx {
CONFIG += static
QMAKE_CXXFLAGS += -static

QMAKE_LFLAGS += -Wl,-rpath=\'\$\$ORIGIN\'/../lib
#QMAKE_CXXFLAGS += "-fno-sized-deallocation"


}

macx{
ICON = icons/abcIcon.icns

}

win32 {
RC_ICONS = icons/abcIcon.ico

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target
}


