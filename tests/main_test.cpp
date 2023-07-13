#include <QtTest/QTest>
#include <QSignalSpy>
#include "ui_mainwindow.h"
#include "../mainwindow.h"

/*
class Main_Tests : public QObject {
    Q_OBJECT
private slots:

    // Create Test Cases Here

    void checkQTestConfiguredSuccessfully(){
        QTest::addColumn<QString>("aString");
        QTest::addColumn<int>("expected");

        QTest::newRow("positive value") << "42" << 42;
        QTest::newRow("negative value") << "-42" << -42;
        QTest::newRow("zero") << "0" << 0;
    }

    // Basic testing if mainwindow can produce output.
    // Wanting to check if the output being uploaded to the QDockWidget is working correctly
    // While checking for bugs through these test cases.
    void testBasicProcessOutput() { }

    void testMainwindowUI() { }
};
*/


class Main_Tests : public QMainWindow{
    Q_OBJECT
public:
    Main_Tests(QWidget* parent=nullptr) : QMainWindow(parent), ui(new Ui::MainWindow) {
        ui->setupUi(this);
    }

    ~Main_Tests(){
        delete ui;
    }

private:
    void testingCaseVisibility() {}

    // void testCaseVisibility2() {}

    // Just testing that QTest is working successfully, and test cases are visible
    void checkQTestConfiguredSuccessfully(){
        QTest::addColumn<QString>("aString");
        QTest::addColumn<int>("expected");

        QTest::newRow("positive value") << "42" << 42;
        QTest::newRow("negative value") << "-42" << -42;
        QTest::newRow("zero") << "0" << 0;

        QCOMPARE(3, 4);
    }




private:
    Ui::MainWindow* ui;
};

QTEST_MAIN(Main_Tests);
#include "main_test.moc"