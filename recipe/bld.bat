@echo ON
setlocal enabledelayedexpansion

mkdir build
cd build

if "%qt_version%"=="5" set WITH_QT="-DWITH_QT=5"
if "%qt_version%"=="6" set WITH_QT="-DWITH_QT=6"
:REM hmaarrfk -- 2025/05
:REM Qt 6.9 seems to be injecting bad flags into the build process
:REM https://github.com/conda-forge/qt-main-feedstock/issues/332
if "%qt_version%"=="6" python -c "import os; p = os.path.join(os.environ['LIBRARY_PREFIX'], 'lib', 'cmake', 'Qt6Test', 'Qt6TestTargets.cmake'); lines = open(p).readlines(); open(p, 'w').writelines(l for l in lines if 'INTERFACE_COMPILE_DEFINITIONS' not in l)"
if "%qt_version%"=="none" set WITH_QT="-DWITH_QT=0"

for /F "tokens=1,2 delims=. " %%a in ("%PY_VER%") do (
   set "PY_MAJOR=%%a"
   set "PY_MINOR=%%b"
)
set PY_LIB=python%PY_MAJOR%%PY_MINOR%.lib

:: Workaround for building LAPACK headers with C++17
:: see https://github.com/conda-forge/opencv-feedstock/pull/363#issuecomment-1604972688
set "CXXFLAGS=%CXXFLAGS% -D_CRT_USE_C_COMPLEX_H"

:: CMake/OpenCV like Unix-style paths for some reason.
set UNIX_PREFIX=%PREFIX:\=/%
set UNIX_LIBRARY_PREFIX=%LIBRARY_PREFIX:\=/%
set UNIX_LIBRARY_BIN=%LIBRARY_BIN:\=/%
set UNIX_LIBRARY_INC=%LIBRARY_INC:\=/%
set UNIX_LIBRARY_LIB=%LIBRARY_LIB:\=/%
set UNIX_SP_DIR=%SP_DIR:\=/%
set UNIX_SRC_DIR=%SRC_DIR:\=/%

:: FFMPEG building requires pkgconfig
set PKG_CONFIG_PATH=%UNIX_LIBRARY_PREFIX%/lib/pkgconfig

for /F "delims=" %%i in ('python -c "import numpy; print(numpy.get_include())"') do set NUMPY_INCLUDE=%%i
set UNIX_NUMPY_INCLUDE=%NUMPY_INCLUDE:\=/%

cmake -LAH -G "Ninja"                                                               ^
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
    -DWITH_AVIF=1                                                                   ^
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
    -DBUILD_OPENEXR=0                                                               ^
    -DWITH_OPENEXR=1                                                                ^
    -DBUILD_JASPER=0                                                                ^
    -DWITH_JASPER=1                                                                 ^
    -DWITH_OPENJPEG=0                                                               ^
    -DBUILD_JPEG=0                                                                  ^
    -DBUILD_WEBP=0                                                                  ^
    -DWITH_WEBP=1                                                                   ^
    -DWITH_CUDA=0                                                                   ^
    -DWITH_OPENCL=0                                                                 ^
    -DWITH_OPENCLAMDFFT=0                                                           ^
    -DWITH_OPENCLAMDBLAS=0                                                          ^
    -DWITH_OPENCL_D3D11_NV=0                                                        ^
    -DWITH_OPENVINO=1                                                               ^
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
    %WITH_QT%                                                                       ^
    -DINSTALL_C_EXAMPLES=0                                                          ^
    -DOPENCV_EXTRA_MODULES_PATH=%UNIX_SRC_DIR%/opencv_contrib/modules               ^
    -DPYTHON_EXECUTABLE=""                                                          ^
    -DPYTHON_INCLUDE_DIR=""                                                         ^
    -DPYTHON_PACKAGES_PATH=""                                                       ^
    -DPYTHON_LIBRARY=""                                                             ^
    -DPYTHON_NUMPY_INCLUDE_DIRS=""                                                  ^
    -DBUILD_opencv_python2=0                                                        ^
    -DPYTHON2_EXECUTABLE=""                                                         ^
    -DPYTHON2_INCLUDE_DIR=""                                                        ^
    -DPYTHON2_NUMPY_INCLUDE_DIRS=""                                                 ^
    -DPYTHON2_LIBRARY=""                                                            ^
    -DPYTHON2_PACKAGES_PATH=""                                                      ^
    -DOPENCV_PYTHON2_INSTALL_PATH=""                                                ^
    -DBUILD_opencv_python3=0                                                        ^
    -DPYTHON_EXECUTABLE=%UNIX_PREFIX%/python                                        ^
    -DPYTHON_INCLUDE_DIR=%UNIX_PREFIX%/include                                      ^
    -DPYTHON_PACKAGES_PATH=%UNIX_SP_DIR%                                            ^
    -DPYTHON_LIBRARY=%UNIX_PREFIX%/libs/%PY_LIB%                                    ^
    -DPYTHON_NUMPY_INCLUDE_DIRS=%UNIX_NUMPY_INCLUDE%                                ^
    -DBUILD_opencv_python3=1                                                        ^
    -DOPENCV_SKIP_PYTHON_LOADER=0                                                   ^
    -DPYTHON3_EXECUTABLE=%UNIX_PREFIX%/python                                       ^
    -DPYTHON3_INCLUDE_DIR=%UNIX_PREFIX%/include                                     ^
    -DPYTHON3_NUMPY_INCLUDE_DIRS=%UNIX_NUMPY_INCLUDE%                               ^
    -DPYTHON3_LIBRARY=%UNIX_PREFIX%/libs/%PY_LIB%                                   ^
    -DPYTHON3_PACKAGES_PATH=%UNIX_SP_DIR%                                           ^
    -DOPENCV_PYTHON3_INSTALL_PATH=%UNIX_SP_DIR%                                     ^
    -DOPENCV_PYTHON_PIP_METADATA_INSTALL=ON                                         ^
    -DOPENCV_PYTHON_PIP_METADATA_INSTALLER:STRING="conda"                           ^
    ..
if %ERRORLEVEL% neq 0 (type CMakeError.log && exit 1)

cmake --build . --target install --config Release
if %ERRORLEVEL% neq 0 exit 1
