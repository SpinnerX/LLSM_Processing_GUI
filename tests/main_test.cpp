#include <QtTest/QTest>
#include <QSignalSpy>
#include "ui_mainwindow.h"
#include "../mainwindow.h"

// We will use this to emulate how our widgets will work, for right now
// Then we will use Main_Tests to create test cases for our application

class MainwindowModel : public QObject {
    Q_OBJECT

private slots:
    
};


class Main_Tests : public QObject{
    Q_OBJECT
public:
    Main_Tests(){
        ui = new Ui::MainWindow();
    }

    ~Main_Tests(){
        delete ui;
    }

private slots:

    void testingCaseVisibility() {
    }

    // Just testing that QTest is working successfully, and test cases are visible
    void checkQTestConfiguredSuccessfully(){
        QTest::addColumn<QString>("aString");
        QTest::addColumn<int>("expected");

        QTest::newRow("positive value") << "42" << 42;
        QTest::newRow("negative value") << "-42" << -42;
        QTest::newRow("zero") << "0" << 0;

        // QTest::keyClicks(ui->customPatternsLineEdit, "Hi");
    }

private:
    Ui::MainWindow* ui;
};

QTEST_MAIN(Main_Tests);
#include "main_test.moc"