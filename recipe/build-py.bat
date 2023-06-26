@echo ON

mkdir build-py
cd build-py

for /F "tokens=1,2 delims=. " %%a in ("%PY_VER%") do (
   set "PY_MAJOR=%%a"
   set "PY_MINOR=%%b"
)
set PY_LIB=python%PY_MAJOR%%PY_MINOR%.lib

:: need to run with OPENCV_INITIAL_PASS=ON first to run generation steps in
:: https://github.com/opencv/opencv/blob/4.7.0/modules/python/bindings/CMakeLists.txt
cmake -G "Ninja"                                                            ^
    -DBUILD_SHARED_LIBS=ON                                                  ^
    -DCMAKE_BUILD_TYPE="Release"                                            ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX%                                    ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX%                                 ^
    -DMY_SUPER_SECRET_VARIABLE=ON                                           ^
    -DOPENCV_INITIAL_PASS=ON                                                ^
    -DOPENCV_PYTHON_STANDALONE_INSTALL_PATH=%SP_DIR%                        ^
    -DOPENCV_PYTHON_PIP_METADATA_INSTALL=ON                                 ^
    -DOPENCV_PYTHON_PIP_METADATA_INSTALLER="conda"                          ^
    -DOPENCV_SKIP_PYTHON_LOADER=ON                                          ^
    -DPYTHON_EXECUTABLE=%PREFIX%\python                                     ^
    -DPYTHON_INCLUDE_DIR=%PREFIX%\include                                   ^
    -DPYTHON_LIBRARY=%PREFIX%\libs\%PY_LIB%                                 ^
    -DPYTHON_NUMPY_INCLUDE_DIRS=%SP_DIR%\numpy\core\include                 ^
    -DPYTHON_PACKAGES_PATH=%SP_DIR%                                         ^
    -DBUILD_opencv_python2=OFF                                              ^
    -DBUILD_opencv_python3=ON                                               ^
    ..\modules\python
if %ERRORLEVEL% neq 0 exit 1

cmake --build .
if %ERRORLEVEL% neq 0 exit 1

:: run actual build
cmake -G "Ninja"                                                            ^
    -DOPENCV_PYTHON_STANDALONE_INSTALL_PATH=%SP_DIR%                        ^
    -DOPENCV_PYTHON_PIP_METADATA_INSTALL=ON                                 ^
    -DOPENCV_PYTHON_PIP_METADATA_INSTALLER="conda"                          ^
    -DOPENCV_SKIP_PYTHON_LOADER=ON                                          ^
    -DPYTHON_EXECUTABLE=%PREFIX%\python                                     ^
    -DPYTHON_INCLUDE_DIR=%PREFIX%\include                                   ^
    -DPYTHON_LIBRARY=%PREFIX%\libs\%PY_LIB%                                 ^
    -DPYTHON_NUMPY_INCLUDE_DIRS=%SP_DIR%\numpy\core\include                 ^
    -DPYTHON_PACKAGES_PATH=%SP_DIR%                                         ^
    ..\modules\python
if %ERRORLEVEL% neq 0 exit 1

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 exit 1

:: clean up between builds
cd ..
rmdir /s /q build-py
