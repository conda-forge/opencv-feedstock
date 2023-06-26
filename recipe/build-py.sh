#!/usr/bin/env bash
set -ex

mkdir -p build-py
cd build-py

IS_PYPY=$(${PYTHON} -c "import platform; print(int(platform.python_implementation() == 'PyPy'))")

LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}${SHLIB_EXT}"
if [[ ${IS_PYPY} == "1" ]]; then
    INC_PYTHON="$PREFIX/include/pypy${PY_VER}"
else
    INC_PYTHON="$PREFIX/include/python${PY_VER}"
fi

# need to run with OPENCV_INITIAL_PASS=ON first to run generation steps in
# https://github.com/opencv/opencv/blob/4.7.0/modules/python/bindings/CMakeLists.txt
cmake -G "Ninja"                                                            \
    ${CMAKE_ARGS}                                                           \
    -BUILD_SHARED_LIBS=ON                                                   \
    -DCMAKE_BUILD_TYPE="Release"                                            \
    -DCMAKE_PREFIX_PATH=${PREFIX}                                           \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}                                        \
    -DMY_SUPER_SECRET_VARIABLE=ON                                           \
    -DOPENCV_INITIAL_PASS=ON                                                \
    -DOPENCV_PYTHON_INSTALL_PATH=${SP_DIR}                                  \
    -DOPENCV_PYTHON_PIP_METADATA_INSTALL=ON                                 \
    -DOPENCV_PYTHON_PIP_METADATA_INSTALLER="conda"                          \
    -DOPENCV_SKIP_PYTHON_LOADER=ON                                          \
    -DPYTHON_EXECUTABLE=${PYTHON}                                           \
    -DPYTHON_INCLUDE_DIR=${INC_PYTHON}                                      \
    -DPYTHON_LIBRARY=${LIB_PYTHON}                                          \
    -DPYTHON_NUMPY_INCLUDE_DIRS=${SP_DIR}/numpy/core/include                \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                        \
    -DBUILD_opencv_python2=OFF                                              \
    -DBUILD_opencv_python3=ON                                               \
    ../modules/python

cmake --build .

# debug
ls -R .

# run actual build
cmake -G "Ninja"                                                            \
    -DOPENCV_PYTHON_PIP_METADATA_INSTALL=ON                                 \
    -DOPENCV_PYTHON_PIP_METADATA_INSTALLER="conda"                          \
    -DOPENCV_SKIP_PYTHON_LOADER=ON                                          \
    -DPYTHON_EXECUTABLE=${PYTHON}                                           \
    -DPYTHON_INCLUDE_DIR=${INC_PYTHON}                                      \
    -DPYTHON_LIBRARY=${LIB_PYTHON}                                          \
    -DPYTHON_NUMPY_INCLUDE_DIRS=${SP_DIR}/numpy/core/include                \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                        \
    ../modules/python

cmake --build . --target install --config Release

# clean up between builds
cd ..
rm -rf build-py
