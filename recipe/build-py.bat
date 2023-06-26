@echo ON

mkdir build-py
cd build-py

for /F "tokens=1,2 delims=. " %%a in ("%PY_VER%") do (
   set "PY_MAJOR=%%a"
   set "PY_MINOR=%%b"
)
set PY_LIB=python%PY_MAJOR%%PY_MINOR%.lib

cmake -G "Ninja"                                                            ^
    -DCMAKE_BUILD_TYPE="Release"                                            ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX%                                    ^
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
    -DOpenCV_BINARY_DIR=%LIBRARY_LIB%                                       ^
    ..\modules\python
if %ERRORLEVEL% neq 0 exit 1

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 exit 1

:: clean up between builds
cd ..
rmdir /s /q build-py
