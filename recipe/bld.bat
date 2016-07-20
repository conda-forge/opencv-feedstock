@echo ON

git clone https://github.com/opencv/opencv_contrib --single-branch --branch %PKG_VERSION% --depth 1

rem Patches apply only to opencv_contrib so we have to apply them now (after source download above)
rem Fixed: https://github.com/Itseez/opencv_contrib/blob/6cd8e9f556c8c55c05178dec05d5277ae00020d9/modules/tracking/src/trackerKCF.cpp#L669
git apply --whitespace=fix -p0 "%RECIPE_DIR%\kcftracker.patch"
rem Fixed: https://github.com/Itseez/opencv_contrib/blob/master/modules/text/src/ocr_beamsearch_decoder.cpp#L569
git apply --whitespace=fix -p0 "%RECIPE_DIR%\ocr_beamsearch_decoder.patch"
rem Fixed: https://github.com/Itseez/opencv_contrib/blob/master/modules/text/src/ocr_hmm_decoder.cpp#L985
git apply --whitespace=fix -p0 "%RECIPE_DIR%\ocr_hmm_decoder.patch"
rem Fixed: https://github.com/Itseez/opencv_contrib/blob/master/modules/dpm/src/dpm_nms.cpp#L43
git apply --whitespace=fix -p0 "%RECIPE_DIR%\dpm.patch"

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

cmake .. -LAH -G "NMake Makefiles"                                    ^
    -DWITH_EIGEN=1                                                    ^
    -DBUILD_TESTS=0                                                   ^
    -DBUILD_DOCS=0                                                    ^
    -DBUILD_PERF_TESTS=0                                              ^
    -DBUILD_ZLIB=0                                                    ^
    -DBUILD_opencv_bioinspired=0                                      ^
    -DBUILD_TIFF=0                                                    ^
    -DBUILD_PNG=0                                                     ^
    -DBUILD_OPENEXR=1                                                 ^
    -DBUILD_JASPER=1                                                  ^
    -DBUILD_JPEG=0                                                    ^
    -DWITH_CUDA=0                                                     ^
    -DWITH_OPENCL=0                                                   ^
    -DWITH_OPENNI=0                                                   ^
    -DWITH_FFMPEG=0                                                   ^
    -DWITH_VTK=0                                                      ^
    -DINSTALL_C_EXAMPLES=0                                            ^
    -DOPENCV_EXTRA_MODULES_PATH=%SRC_DIR%\opencv_contrib\modules      ^
    -DCMAKE_BUILD_TYPE="Release"                                      ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX%                           ^
    -DEXECUTABLE_OUTPUT_PATH=%LIBRARY_BIN%                            ^
    -DLIBRARY_OUTPUT_PATH=%LIBRARY_BIN%                               ^
    -DPYTHON%PY_MAJOR%_EXECUTABLE=%PREFIX%\python                     ^
    -DPYTHON_INCLUDE_DIR=%PREFIX%\include                             ^
    -DPYTHON_PACKAGES_PATH=%SP_DIR%                                   ^
    -DPYTHON_LIBRARY=%PREFIX%\libs\%PY_LIB%                           ^
    -DPYTHON%PY_MAJOR%_NUMPY_INCLUDE_DIRS=%SP_DIR%\numpy\core\include
if errorlevel 1 exit 1

cmake --build . --target INSTALL --config Release
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
