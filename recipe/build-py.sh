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

cmake -G "Ninja"                                                            \
    ${CMAKE_ARGS}                                                           \
    -DCMAKE_BUILD_TYPE="Release"                                            \
    -DCMAKE_PREFIX_PATH=${PREFIX}                                           \
    -DOPENCV_PYTHON_STANDALONE_INSTALL_PATH=${SP_DIR}                       \
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
    -DOpenCV_BINARY_DIR=${PREFIX}/lib                                       \
    ../modules/python

cmake --build . --target install --config Release

# clean up between builds
cd ..
rm -rf build-py
