@echo ON
setlocal enabledelayedexpansion

:: We install two local pythons so that we can build everything at once.
:: The 2nd Python 3 variant does of course cause us problems that we hack
:: around in install-py-opencv.sh, still better than building all of libopencv
:: 6 times instead of twice (3 * python, 2 * hdf5).
call conda create -yp %CD%\py2 --override-channels -c https://repo.continuum.io/pkgs/main python=2.7 numpy=1.11
call conda create -yp %CD%\py3 --override-channels -c https://repo.continuum.io/pkgs/main python=3.6 numpy=1.11

mkdir build
cd build

if "%PY3K%" == "0" (
    echo "Copying stdint.h for windows"
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\calib3d\include\stdint.h
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\videoio\include\stdint.h
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\highgui\include\stdint.h
)

for /F "tokens=1,2 delims=. " %%a in ("%PY_VER%") do (
   set "PY_MAJOR=%%a"
   set "PY_MINOR=%%b"
)
set PY_LIB=python%PY_MAJOR%%PY_MINOR%.lib

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
    -DBUILD_opencv_python2=1                                                        ^
    -DPYTHON2_EXECUTABLE=%U_SRC_DIR%/py2/python                                     ^
    -DPYTHON2_INCLUDE_DIR=%U_SRC_DIR%/py2/include                                   ^
    -DPYTHON2_NUMPY_INCLUDE_DIRS=%U_SRC_DIR%/py2/Lib/site-packages/numpy/core/include ^
    -DPYTHON2_LIBRARY=%U_SRC_DIR%/py2/libs/python27.lib                             ^
    -DPYTHON2_PACKAGES_PATH=%U_SRC_DIR%/py2/Lib/site-packages                       ^
    -DBUILD_opencv_python3=1                                                        ^
    -DPYTHON3_EXECUTABLE=%U_SRC_DIR%/py3/python                                     ^
    -DPYTHON3_INCLUDE_DIR=%U_SRC_DIR%/py3/include                                   ^
    -DPYTHON3_NUMPY_INCLUDE_DIRS=%U_SRC_DIR%/py3/Lib/site-packages/numpy/core/include ^
    -DPYTHON3_LIBRARY=%U_SRC_DIR%/py3/libs/python36.lib                             ^
    -DPYTHON3_PACKAGES_PATH=%U_SRC_DIR%/py3/Lib/site-packages                       ^
    -DEXECUTABLE_OUTPUT_PATH=%U_LIBRARY_BIN%                                        ^
    -DLIBRARY_OUTPUT_PATH=%U_LIBRARY_BIN%                                           ^
    -DOPENCV_EXTRA_MODULES_PATH=%U_SRC_DIR%/opencv_contrib-%PKG_VERSION%/modules

if errorlevel 1 exit 1
cmake --build . --target all --config Release
