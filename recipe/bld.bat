@echo ON
setlocal enabledelayedexpansion


if "%PY3K%" == "0" (
    echo "Copying stdint.h for windows"
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\calib3d\include\stdint.h
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\videoio\include\stdint.h
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\highgui\include\stdint.h
)

mkdir build
cd build

:: Workaround for building LAPACK headers with C++17
:: see https://github.com/conda-forge/opencv-feedstock/pull/363#issuecomment-1604972688
set "CXXFLAGS=%CXXFLAGS% -D_CRT_USE_C_COMPLEX_H"

:: CMake/OpenCV like Unix-style paths for some reason.
set UNIX_LIBRARY_PREFIX=%LIBRARY_PREFIX:\=/%
set UNIX_LIBRARY_INC=%LIBRARY_INC:\=/%
set UNIX_LIBRARY_LIB=%LIBRARY_LIB:\=/%
set UNIX_SRC_DIR=%SRC_DIR:\=/%

:: FFMPEG building requires pkgconfig
set PKG_CONFIG_PATH=%UNIX_LIBRARY_PREFIX%/lib/pkgconfig

cmake -G "Ninja"                                                                    ^
    -DBUILD_SHARED_LIBS=ON                                                          ^
    -DCMAKE_CXX_STANDARD=17                                                         ^
    -DCMAKE_BUILD_TYPE="Release"                                                    ^
    -DCMAKE_INSTALL_PREFIX=%UNIX_LIBRARY_PREFIX%                                    ^
    -DCMAKE_PREFIX_PATH=%UNIX_LIBRARY_PREFIX%                                       ^
    -DOPENCV_CONFIG_INSTALL_PATH=cmake                                              ^
    -DOPENCV_BIN_INSTALL_PATH=bin                                                   ^
    -DOPENCV_LIB_INSTALL_PATH=lib                                                   ^
    -DOPENCV_GENERATE_SETUPVARS=OFF                                                 ^
    -DOPENCV_DOWNLOAD_TRIES=1;2;3;4;5                                               ^
    -DOPENCV_DOWNLOAD_PARAMS=INACTIVITY_TIMEOUT;30;TIMEOUT;180;SHOW_PROGRESS        ^
    -DWITH_LAPACK=1                                                                 ^
    -DLAPACK_INCLUDE_DIR=%UNIX_LIBRARY_INC%                                         ^
    -DLAPACK_LAPACKE_H=lapacke.h                                                    ^
    -DLAPACK_CBLAS_H=cblas.h                                                        ^
    -DLAPACK_LIBRARIES=%UNIX_LIBRARY_LIB%/lapack.lib;%UNIX_LIBRARY_LIB%/cblas.lib   ^
    -DWITH_EIGEN=1                                                                  ^
    -DENABLE_CONFIG_VERIFICATION=ON                                                 ^
    -DENABLE_PRECOMPILED_HEADERS=OFF                                                ^
    -DBUILD_TESTS=0                                                                 ^
    -DBUILD_DOCS=0                                                                  ^
    -DBUILD_PERF_TESTS=0                                                            ^
    -DBUILD_ZLIB=0                                                                  ^
    -DBUILD_opencv_bioinspired=0                                                    ^
    -DBUILD_TIFF=0                                                                  ^
    -DBUILD_PNG=0                                                                   ^
    -DWITH_PROTOBUF=1                                                               ^
    -DBUILD_PROTOBUF=0                                                              ^
    -DPROTOBUF_UPDATE_FILES=1                                                       ^
    -DBUILD_OPENEXR=1                                                               ^
    -DBUILD_JASPER=0                                                                ^
    -DWITH_JASPER=1                                                                 ^
    -DWITH_OPENJPEG=0                                                               ^
    -DBUILD_JPEG=0                                                                  ^
    -DWITH_CUDA=0                                                                   ^
    -DWITH_OPENCL=0                                                                 ^
    -DWITH_OPENCLAMDFFT=0                                                           ^
    -DWITH_OPENCLAMDBLAS=0                                                          ^
    -DWITH_OPENCL_D3D11_NV=0                                                        ^
    -DWITH_1394=0                                                                   ^
    -DWITH_OPENNI=0                                                                 ^
    -DWITH_HDF5=1                                                                   ^
    -DOPENCV_ENABLE_PKG_CONFIG=1                                                    ^
    -DWITH_FFMPEG=1                                                                 ^
    -DWITH_TENGINE=0                                                                ^
    -DWITH_GSTREAMER=0                                                              ^
    -DWITH_TESSERACT=0                                                              ^
    -DWITH_VTK=0                                                                    ^
    -DWITH_WIN32UI=0                                                                ^
    -DWITH_QT=5                                                                     ^
    -DINSTALL_C_EXAMPLES=0                                                          ^
    -DOPENCV_EXTRA_MODULES_PATH=%UNIX_SRC_DIR%/opencv_contrib/modules               ^
    -DOPENCV_PYTHON_SKIP_DETECTION=ON                                               ^
    -DBUILD_opencv_python2=0                                                        ^
    -DBUILD_opencv_python3=0                                                        ^
    ..
if %ERRORLEVEL% neq 0 (type CMakeError.log && exit 1)

cmake --build .
if %ERRORLEVEL% neq 0 exit 1
