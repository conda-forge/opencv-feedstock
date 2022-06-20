@echo ON
setlocal EnableDelayedExpansion
md build
pushd build

if "%vc%" == "9" (
  echo "Copying stdint.h for windows"
  copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\calib3d\include\stdint.h
  copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\videoio\include\stdint.h
  copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\highgui\include\stdint.h
)

:: The following options are set in a way to make sure that the cmake files for
:: both the main library and modules/functionality are detected correctly by
:: downstreams... modify with caution:  OPENCV_CONFIG_INSTALL_PATH
:: OPENCV_INSTALL_BINARIES_PREFIX OPENCV_INSTALL_BINARIES_SUFFIX
rem Note that though a dependency may be installed it may not be detected
rem correctly by this build system and so some functionality may be disabled
rem (this is more frequent on Windows but does sometimes happen on other OSes).
rem Note that -DBUILD_x=0 may not be honoured for any particular dependency x.
rem If -DHAVE_x=1 is used it may be that the undetected conda package is
rem ignored in lieu of libraries that are built as part of this build (this
rem will likely result in an overdepending error). Check the 3rdparty libraries
rem directory in the build directory to see what has been vendored by the
rem opencv build


cmake .. -LAH -G Ninja                                                              ^
    -DOPENCV_GENERATE_PKGCONFIG=ON ^
    -DBUILD_DOCS=0                                                                  ^
    -DBUILD_IPP_IW=0                                                                ^
    -DBUILD_JASPER=0                                                                ^
    -DBUILD_JAVA=0                                                                  ^
    -DBUILD_JPEG=0                                                                  ^
    -DBUILD_OPENEXR=0                                                               ^
    -DBUILD_OPENJPEG=0                                                              ^
    -DBUILD_PERF_TESTS=0                                                            ^
    -DBUILD_PNG=0                                                                   ^
    -DBUILD_PROTOBUF=0                                                              ^
    -DBUILD_SHARED_LIBS=ON                                                          ^
    -DBUILD_TBB=0                                                                   ^
    -DBUILD_TESTS=0                                                                 ^
    -DBUILD_TIFF=0                                                                  ^
    -DBUILD_WEBP=0                                                                  ^
    -DBUILD_WITH_STATIC_CRT=0                                                       ^
    -DBUILD_ZLIB=0                                                                  ^
    -DBUILD_opencv_bioinspired=0                                                    ^
    -DBUILD_opencv_python2=0                                                        ^
    -DBUILD_opencv_python3=1                                                        ^
    -DCMAKE_BUILD_TYPE="Release"                                                    ^
    -DCMAKE_FIND_ROOT_PATH=%PREFIX%;%BUILD_PREFIX%                                  ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX%                                         ^
    -DCMAKE_SYSTEM_PREFIX_PATH=%LIBRARY_PREFIX%                                     ^
    -DENABLE_CONFIG_VERIFICATION=ON                                                 ^
    -DENABLE_PRECOMPILED_HEADERS=OFF                                                ^
    -DINSTALL_C_EXAMPLES=0                                                          ^
    -DOPENCV_BIN_INSTALL_PATH=bin                                                   ^
    -DOPENCV_CONFIG_INSTALL_PATH="lib/cmake/"                                       ^
    -DOPENCV_DOWNLOAD_PARAMS=INACTIVITY_TIMEOUT;30;TIMEOUT;180;SHOW_PROGRESS        ^
    -DOPENCV_DOWNLOAD_TRIES=1;2;3;4;5                                               ^
    -DOPENCV_EXTRA_MODULES_PATH=%SRC_DIR%/opencv_contrib-%PKG_VERSION%/modules      ^
    -DOPENCV_GENERATE_SETUPVARS=OFF                                                 ^
    -DOPENCV_INSTALL_BINARIES_PREFIX="opencv"                                       ^
    -DOPENCV_INSTALL_BINARIES_SUFFIX=""                                             ^
    -DOPENCV_LIB_INSTALL_PATH=lib                                                   ^
    -DOPENCV_PYTHON2_INSTALL_PATH=""                                                ^
    -DOPENCV_PYTHON3_INSTALL_PATH=%SP_DIR%                                          ^
    -DOPENCV_SKIP_PYTHON_LOADER=1                                                   ^
    -DPROTOBUF_UPDATE_FILES=1                                                       ^
    -DPYTHON3_EXECUTABLE=%PREFIX%/python.exe                                        ^
    -DPYTHON_DEFAULT_EXECUTABLE=%PREFIX%/python.exe                                 ^
    -DWEBP_LIBRARY=%PREFIX%/Library/lib/libwebp.lib                                 ^
    -DWEBP_INCLUDE_DIR=%PREFIX%/Library/include                                     ^
    -DWITH_1394=0                                                                   ^
    -DWITH_CUDA=0                                                                   ^
    -DWITH_DIRECTX=0                                                                ^
    -DWITH_EIGEN=1                                                                  ^
    -DWITH_FFMPEG=0                                                                 ^
    -DWITH_GSTREAMER=1                                                              ^
    -DWITH_GTK=0                                                                    ^
    -DWITH_JASPER=0                                                                 ^
    -DWITH_LAPACK=0                                                                 ^
    -DWITH_MSMF_DXVA=0                                                              ^
    -DWITH_OPENCL=0                                                                 ^
    -DWITH_OPENCLAMDBLAS=0                                                          ^
    -DWITH_OPENCLAMDFFT=0                                                           ^
    -DWITH_OPENCL_D3D11_NV=0                                                        ^
    -DWITH_OPENJPEG=0                                                               ^
    -DWITH_OPENNI=0                                                                 ^
    -DWITH_PROTOBUF=1                                                               ^
    -DWITH_QT=5                                                                     ^
    -DWITH_TBB=0                                                                    ^
    -DWITH_TENGINE=0                                                                ^
    -DWITH_TESSERACT=0                                                              ^
    -DWITH_VTK=0                                                                    ^
    -DWITH_WEBP=1                                                                   ^
    -DWITH_WIN32UI=0

if errorlevel 1 exit /b 1
cmake --build .
if errorlevel 1 exit /b 1
echo cmake --build . ok
echo exiting the lot OK.
exit /b 0
