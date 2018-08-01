@echo ON
setlocal EnableDelayedExpansion

mkdir build
pushd build

if "%vc%" == "9" (
  echo "Copying stdint.h for windows"
  copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\calib3d\include\stdint.h
  copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\videoio\include\stdint.h
  copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\highgui\include\stdint.h
)

:: CMake/OpenCV like Unix-style paths for some reason.
set U_PREFIX=%PREFIX:\=/%
set U_LIBRARY_PREFIX=%LIBRARY_PREFIX:\=/%
set U_LIBRARY_BIN=%LIBRARY_BIN:\=/%
set U_SP_DIR=%SP_DIR:\=/%
set U_SRC_DIR=%SRC_DIR:\=/%

cmake .. -LAH -G "NMake Makefiles JOM"                                              ^
    -DCMAKE_BUILD_TYPE="Release"                                                    ^
    -DCMAKE_INSTALL_PREFIX=%U_LIBRARY_PREFIX%                                       ^
    -DWITH_EIGEN=1                                                                  ^
    -DBUILD_TESTS=0                                                                 ^
    -DBUILD_DOCS=0                                                                  ^
    -DBUILD_PERF_TESTS=0                                                            ^
    -DBUILD_ZLIB=0                                                                  ^
    -DBUILD_opencv_bioinspired=0                                                    ^
    -DBUILD_TIFF=0                                                                  ^
    -DBUILD_PNG=0                                                                   ^
    -DBUILD_OPENEXR=1                                                               ^
    -DBUILD_JASPER=0                                                                ^
    -DBUILD_JPEG=0                                                                  ^
    -DWITH_CUDA=0                                                                   ^
    -DWITH_OPENCL=0                                                                 ^
    -DWITH_OPENNI=0                                                                 ^
    -DWITH_FFMPEG=1                                                                 ^
    -DWITH_MATLAB=0                                                                 ^
    -DWITH_VTK=0                                                                    ^
    -DWITH_GTK=0                                                                    ^
    -DINSTALL_C_EXAMPLES=0                                                          ^
    -DOPENCV_EXTRA_MODULES_PATH=%U_SRC_DIR%/opencv_contrib-%PKG_VERSION%/modules    ^
    -DEXECUTABLE_OUTPUT_PATH=%U_LIBRARY_BIN%                                        ^
    -DLIBRARY_OUTPUT_PATH=%U_LIBRARY_BIN%                                           ^
    -DBUILD_opencv_python3=0                                                        ^
    -DBUILD_opencv_python2=0

if errorlevel 1 exit /b 1
cmake --build . --target all --config Release
if errorlevel 1 exit /b 1
echo cmake --build . --target all --config Release ok
:: The DLLs get built directly in the bin folder, cmake install in install-libopenv will handle this.
del /s /q %LIBRARY_BIN%\opencv*.dll
echo exiting the lot OK.
exit /b 0
