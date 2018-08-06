setlocal EnableDelayedExpansion

:: The Python modules will get copied from their own prefixes.
set PY_VERS=%PY_VER%
:: We install two local pythons so that we can build everything at once.
:: The 2nd Python 3 variant does of course cause us problems that we hack
:: around in install-py-opencv.sh, still better than building all of libopencv
:: 6 times instead of twice (3 * python, 2 * hdf5).
set CONDA_SUBDIR=win-%ARCH%
for %%p in (%PY_VERS%) do (
  call conda create -yp %CD%\py%%p --override-channels -c https://repo.continuum.io/pkgs/main python=%%p numpy=1.11
)

:: Using a per-Python build dir means everything is rebuilt multiple times, but the alternatives do not work.
mkdir build-py%PY_VER%
pushd build-py%PY_VER%
:: In spite of explicitly disabling Python, OpenCV finds PYTHON_DEFAULT_EXECUTABLE (calling it PYTHON_DEFAULT_EXECUTABLE)
:: This is then used in a few places, making bindings for various languages mainly.
:: One roblem with how Python is found is that we end up with this mess (notice difference between Interp and Libs):
:: //Details about finding PythonInterp
:: FIND_PACKAGE_MESSAGE_DETAILS_PythonInterp:INTERNAL=[C:/Miniconda3/conda-bld/opencv-suite_1533077280140/_h_env/python.exe][v3.6.6(2.7)]
:: //Details about finding PythonLibs
:: FIND_PACKAGE_MESSAGE_DETAILS_PythonLibs:INTERNAL=[C:/Miniconda3/libs/python36.lib][C:/Miniconda3/include][v3.6.6(3.6.6)]
:: even if PythonLibs was correct, it's still not the (fake) host env Python we will use later, still we could do text replacement on that.
:: For now trying to delete the cache. Will slow down the build a bit though I expect.
if exist CMakeCache.txt del CMakeCache.txt
:: No idea!
if not exist Release mkdir Release

for %%p in (!PY_VERS!) do (
  echo on
  set PY_DOT_VER=%%p
  set PYVER_NO_DOTS=!PY_DOT_VER:.=!
  set PYLIB=!PYVER_NO_DOTS:~2!
  set SP_DIR_FAKE=%CD%\py%%p\Lib\site-packages
  set SP_DIR_FAKE_U=%SP_DIR_FAKE:\=/%
  set U_SRC_DIR=%SRC_DIR:\=/%
  set U_LIBRARY_PREFIX=%LIBRARY_PREFIX:\=/%
  set U_LIBRARY_BIN=%LIBRARY_BIN:\=/%

  set
  if "%vc%" == "9" (
    cmake .. -LAH -G "NMake Makefiles JOM"                                            ^
      -DCMAKE_BUILD_TYPE="Release"                                                    ^
      -DCMAKE_INSTALL_PREFIX=!U_LIBRARY_PREFIX!                                       ^
      -DOpenCV_INSTALL_BINARIES_PREFIX=""                                             ^
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
      -DOPENCV_EXTRA_MODULES_PATH=!U_SRC_DIR!/opencv_contrib-%PKG_VERSION%/modules    ^
      -DEXECUTABLE_OUTPUT_PATH=!U_LIBRARY_BIN!                                        ^
      -DLIBRARY_OUTPUT_PATH=!U_LIBRARY_BIN!                                           ^
      -DBUILD_opencv_python2=1                                                        ^
      -DPYTHON2_EXECUTABLE=!U_SRC_DIR!/py2.7/python.exe                               ^
      -DPYTHON2_INCLUDE_DIR=!U_SRC_DIR!/py2.7/include                                 ^
      -DPYTHON2_NUMPY_INCLUDE_DIRS=!U_SRC_DIR!/py2.7/Lib/site-packages/numpy/core/include ^
      -DPYTHON2_LIBRARY=!U_SRC_DIR!/py2.7/libs/python!PYVER_NO_DOTS!.lib              ^
      -DPYTHON2_PACKAGES_PATH=!U_SRC_DIR!/py2.7/Lib/site-packages                     ^
      -DBUILD_opencv_python3=0
    if errorlevel 1 exit /b 1
    echo cmake python2 configure ok
    cmake --build . --target opencv_python2 --config Release
    if errorlevel 1 exit /b 1
    echo "cmake --build . --target opencv_python2 --config Release"
  ) else (
    cmake .. -LAH -G "NMake Makefiles JOM"                                            ^
      -DCMAKE_BUILD_TYPE="Release"                                                    ^
      -DCMAKE_INSTALL_PREFIX=!U_LIBRARY_PREFIX!                                       ^
      -DOpenCV_INSTALL_BINARIES_PREFIX=""                                             ^
      -DOPENCV_CONFIG_INSTALL_PATH=!U_LIBRARY_PREFIX!                                 ^
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
      -DOPENCV_EXTRA_MODULES_PATH=!U_SRC_DIR!/opencv_contrib-%PKG_VERSION%/modules    ^
      -DEXECUTABLE_OUTPUT_PATH=!U_LIBRARY_BIN!                                        ^
      -DLIBRARY_OUTPUT_PATH=!U_LIBRARY_BIN!                                           ^
      -DBUILD_opencv_python2=0                                                        ^
      -DBUILD_opencv_python3=1                                                        ^
      -DPYTHON3_EXECUTABLE=!U_SRC_DIR!/py%%p/python.exe                               ^
      -DPYTHON3_INCLUDE_DIR=!U_SRC_DIR!/py%%p/include                                 ^
      -DPYTHON3_NUMPY_INCLUDE_DIRS=!U_SRC_DIR!/py%%p/Lib/site-packages/numpy/core/include ^
      -DPYTHON3_LIBRARY=!U_SRC_DIR!/py%%p/libs/python!PYVER_NO_DOTS!.lib              ^
      -DPYTHON3_PACKAGES_PATH=!U_SRC_DIR!/py%%p/Lib/site-packages
    if errorlevel 1 exit /b 1
REM    echo cmake python3 configure ok
REM    CMake makes a pig's ear of reconfiguring (and everything else it does).
REM    dir modules\python3\CMakeFiles\opencv_python3.dir\build.make
REM    pushd modules\python3\CMakeFiles\opencv_python3.dir
REM      rename build.make build.make.orig
REM    popd
REM    %SYS_PYTHON% %RECIPE_DIR%\replace-word-pairs.py "python..\.lib" "python37.lib" < modules\python3\CMakeFiles\opencv_python3.dir\build.make.orig > modules\python3\CMakeFiles\opencv_python3.dir\build.make
    cmake --build . --target all --config Release
    if errorlevel 1 exit /b 1
    cmake --build . --target opencv_python3 --config Release
    if errorlevel 1 exit /b 1
    echo "cmake --build . --target opencv_python3 --config Release"
  )
)
popd

if "%vc%" == "9" (
  copy /Y !SRC_DIR!\build-py%PY_VER%\lib\python2\*.pyd  %SP_DIR%\
) else (
  copy /Y !SRC_DIR!\build-py%PY_VER%\lib\python3\cv2.*!PYVER_NO_DOTS!*.pyd  %SP_DIR%\
)
findstr /C:python!PYVER_NO_DOTS!.dll !SRC_DIR!\build-py%PY_VER%\lib\python3\cv2.*!PYVER_NO_DOTS!*.pyd  %SP_DIR%\cv2*.pyd
if errorlevel 1 exit /b 1

exit /b 0
