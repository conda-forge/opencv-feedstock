@echo ON
setlocal enabledelayedexpansion

curl -L -O "https://github.com/opencv/opencv_contrib/archive/%PKG_VERSION%.tar.gz"
%PYTHON% -c "import tarfile, os; tar = tarfile.open(os.environ['PKG_VERSION'] + '.tar.gz', 'r:gz'); tar.extractall(); tar.close()"
%PYTHON% -c "import hashlib, os; print(hashlib.sha256(open(os.environ['PKG_VERSION'] + '.tar.gz', 'rb').read()).hexdigest())" > sha256.out
SET /p CONTRIB_SHA256=<sha256.out
if NOT "%CONTRIB_SHA256%" == "e94acf39cd4854c3ef905e06516e5f74f26dddfa6477af89558fb40a57aeb444" (
    exit 1
)

if "%PY3K%" == "0" (
    echo "Copying stdint.h for windows"
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\calib3d\include\stdint.h
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\videoio\include\stdint.h
    copy "%LIBRARY_INC%\stdint.h" %SRC_DIR%\modules\highgui\include\stdint.h
 
rem      :: Patch contrib to fix build errors
rem      echo "Patch opencv_contrib to fix Python 2.7 build errors"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_dnn_caffe_template.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_dnn_tf_map_at.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_xfeatures2d_boostdesc_round.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_xfeatures2d_pct_signatures_sqrt.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_ximgproc_bilateral_sqrt.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_ximgproc_round.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_optflow_sqrt.patch"
rem      git apply --ignore-whitespace --whitespace=nowarn -p0 "%RECIPE_DIR%\opencvcontrib_structured_light.patch"
)

mkdir build && cd build

:: CMake/OpenCV like Unix-style paths for some reason.
set UNIX_PREFIX=%PREFIX:\=/%
set UNIX_LIBRARY_PREFIX=%LIBRARY_PREFIX:\=/%
set UNIX_LIBRARY_BIN=%LIBRARY_BIN:\=/%
set UNIX_LIBRARY_INC=%LIBRARY_INC:\=/%
set UNIX_LIBRARY_LIB=%LIBRARY_LIB:\=/%
set UNIX_SP_DIR=%SP_DIR:\=/%
set UNIX_SRC_DIR=%SRC_DIR:\=/%

:: cvv and qt5 don't play well on PY27 https://github.com/opencv/opencv_contrib/issues/577
if "%PY_MAJOR%" == "2" ( set "CVV=off" )
if "%PY_MAJOR%" == "3" ( set "CVV=on" )

cmake -LAH -G "NMake Makefiles"                                                  ^
    -DWITH_EIGEN=1                                                                  ^
    -DBUILD_TESTS=0                                                                 ^
    -DBUILD_DOCS=0                                                                  ^
    -DBUILD_PERF_TESTS=0                                                            ^
    -DBUILD_ZLIB=0                                                                  ^
    -DBUILD_opencv_bioinspired=0                                                    ^
    -DBUILD_TIFF=0                                                                  ^
    -DBUILD_PNG=0                                                                   ^
    -DBUILD_OPENEXR=1                                                               ^
    -DBUILD_JASPER=1                                                                ^
    -DBUILD_JPEG=0                                                                  ^
    -DWITH_CUDA=0                                                                   ^
    -DWITH_OPENCL=0                                                                 ^
    -DWITH_OPENNI=0                                                                 ^
    -DWITH_FFMPEG=1                                                                 ^
    -DWITH_VTK=0                                                                    ^
    -DWITH_QT=5                                                                     ^
    -DINSTALL_C_EXAMPLES=0                                                          ^
    -DOPENCV_EXTRA_MODULES_PATH=%UNIX_SRC_DIR%/opencv_contrib-%PKG_VERSION%/modules ^
    -DBUILD_opencv_cvv=%CVV%                                                        ^
    -DCMAKE_BUILD_TYPE="Release"                                                    ^
    -DCMAKE_INSTALL_PREFIX=%UNIX_LIBRARY_PREFIX%                                    ^
    -DCMAKE_PREFIX_PATH=%UNIX_LIBRARY_PREFIX%                                       ^
    -DEXECUTABLE_OUTPUT_PATH=%UNIX_LIBRARY_BIN%                                     ^
    -DLIBRARY_OUTPUT_PATH=%UNIX_LIBRARY_BIN%                                        ^
    -DPYTHON_NUMPY_INCLUDE_DIRS=%UNIX_SP_DIR%/numpy/core/include                    ^
    -DBUILD_opencv_python%PY_MAJOR%=1                                               ^
    ..
if errorlevel 1 exit 1

cmake --build . --target install --config Release
if errorlevel 1 exit 1

if "%ARCH%" == "32" ( set "OPENCV_ARCH=86")
if "%ARCH%" == "64" ( set "OPENCV_ARCH=64")

robocopy %LIBRARY_PREFIX%\x%OPENCV_ARCH%\vc%VS_MAJOR%\ %LIBRARY_PREFIX%\ *.* /E
if %ERRORLEVEL% GEQ 8 exit 1

rem Remove files installed in the wrong locations
rd /S /Q "%LIBRARY_BIN%\Release"
rd /S /Q "%LIBRARY_PREFIX%\x%OPENCV_ARCH%"
rem RD is a bit horrible and doesn't return an errorcode properly, so
rem the errorcode from robocopy is propagated (which is non-zero), so we
rem forcibly exit 0 here
exit 0
