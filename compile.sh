#compile_tests="compiling tests..."
#run_tests="Running tests..."

#compile="Compiling LLSM..."
#run_app="Running LLSM..."

#testsCmd="--tests"

# This allows us to compile only test cases if the users types
# Example 1, shows if the build file isnt throwing any errors
# Example #1: ./compile --tests
# Example 2, shows if build errors are shown...
# Example #2: ./compile --tests --reset

# Example 3, shows if we want to compile and use the actual application and not test cases
# Example #3: ./compile.sh --build
# Example 4, shows if actual application build is messed up or throwing errors of not being able to build.
# Example #4: ./compile.sh --build --reset

# Just in case I forget how the commands supposed to work!
if [ "$1" == "--help" ]; then
	echo "Helping Hand on using compile.sh"
	echo "compile --build => Build actual application"
	echo "compile --build --reset => Resets the build, and rebuilds the entire application with new build dir."
	echo "compile --tests => Builds the normal test cases"
	echo "compile --tests --reset => Resets the build and rebuilds entire test cases build with new build dir."

	echo "compile --run => running our actual application, not test cases"
	echo "compile --run_tests => this will run our test cases."
fi

if [ "$1" == "--run" ]; then
	echo "Running application..."
	./build/LLSM_Processing_GUI.app/Contents/MacOS/LLSM_Processing_GUI
fi

if [ "$1" == "--run_tests" ]; then
	cd tests && cd build && ./main_test.app/Contents/MacOS/main_test
fi

# Handling test cases main build for the test cases portion of the application.
if [ "$1" == "--tests" ]; then

	# This is just in case we want to rebuild the entire build process for test cases build
	if [ "$2" == "--reset" ]; then
		echo "Rebuilding tests build..."
		cd tests && rm -rf build && mkdir build && cd build && make -j
	else
		echo "Compiling tests..."
		cd tests && cd build && make -j
	fi
fi

# Just for handling the building process for main application
if [ "$1" == "--build" ]; then

	# This is just in case we want to rebuild the entire build process for main application
	if [ "$2" == "--reset" ]; then
		echo "Rebuilding application"
		# rm -rf build && mkdir build && cd build && qmake .. && make -j
		rm -rf build && mkdir build && cd build
		qmake ..

		make -j
		cd ..

		cp -R LLSM5DTools build/LLSM_Processing_GUI.app/Contents/MacOS/
		cp -R AaronFiles/matlabPath build/LLSM_Processing_GUI.app/Contents/MacOS/matlabPath
		cp -R LLSM5DTools build/LLSM_Processing_GUI.app/Contents/MacOS/matlabPath
	else
		echo "Compiling LLSM..."
		# This is to build and run actual application and not the tests
		cd build && make -j
	fi
fi
