#include <QtTest/QTest>
#include "../mainwindowConsoleOutputWindow.h"
#include "../mainwindow.h"


class MainWindowMockTest {
public:
    void testWidgets(){
        
    }


private:
    MainWindow mainApplication;
};

class Main_Tests : public QObject {
    Q_OBJECT
private slots:

    /** Create Test Cases Here **/

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
    void testBasicProcessOutput(){
    }
};

QTEST_MAIN(Main_Tests);
#include "main_test.moc"