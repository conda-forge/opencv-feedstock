#!/bin/bash

SHORT_OS_STR=$(uname -s)

if [ "${SHORT_OS_STR:0:5}" == "Linux" ]; then
    DYNAMIC_EXT="so"
    OPENMP="-DWITH_OPENMP=1"
    CMAKE_OSX_DEPLOYMENT_TARGET=""
    # Compile with C++11 not C++17 standard
    CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
    CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
fi
if [ "${SHORT_OS_STR}" == "Darwin" ]; then
    DYNAMIC_EXT="dylib"
    OPENMP=""
    CMAKE_OSX_DEPLOYMENT_TARGET="-DCMAKE_OSX_DEPLOYMENT_TARGET="
fi

INC_PYTHON="${PREFIX}/include/python${PY_VER}"

mkdir build
cd build

IFS='.' read -ra PY_VER_ARR <<< "${PY_VER}"
PY_MAJOR="${PY_VER_ARR[0]}"

if [ $PY3K -eq 1 ]; then
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}m.${DYNAMIC_EXT}"
    INC_PYTHON="$PREFIX/include/python${PY_VER}m"
else
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}.${DYNAMIC_EXT}"
    INC_PYTHON="$PREFIX/include/python${PY_VER}"
fi

if [[ ${PY_VER} == 3.7 ]]; then
  # Same thing as https://github.com/google/protobuf/issues/4086
  export CFLAGS="${CFLAGS} -fpermissive"
  export CXXFLAGS="${CXXFLAGS} -fpermissive"
fi

cmake .. -LAH                                                             \
    -DCMAKE_BUILD_TYPE="Release"                                          \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                                        \
    -DCMAKE_INSTALL_LIBDIR=lib                                            \
    -DCMAKE_SKIP_RPATH:bool=ON                                            \
    $OPENMP                                                               \
    -DWITH_EIGEN=1                                                        \
    -DBUILD_TESTS=0                                                       \
    -DBUILD_DOCS=0                                                        \
    -DBUILD_PERF_TESTS=0                                                  \
    -DBUILD_ZLIB=0                                                        \
    -DZLIB_LIBRARY_RELEASE=$PREFIX/lib/libz.$DYNAMIC_EXT                  \
    -DZLIB_INCLUDE_DIR=$PREFIX/include                                    \
    -DPNG_INCLUDE_DIR=$PREFIX/include                                     \
    -DPNG_LIBRARY_RELEASE=$PREFIX/lib/libpng.$DYNAMIC_EXT                 \
    -DBUILD_LIBPROTOBUF_FROM_SOURCES=0                                    \
    -DBUILD_PROTOBUF=0                                                    \
    -DPROTOBUF_INCLUDE_DIR=${PREFIX}/include                              \
    -DPROTOBUF_LIBRARIES=${PREFIX}/lib                                    \
    -DBUILD_TIFF=0                                                        \
    -DBUILD_PNG=0                                                         \
    -DBUILD_OPENEXR=1                                                     \
    -DBUILD_JASPER=0                                                      \
    -DBUILD_JPEG=0                                                        \
    -DWITH_CUDA=0                                                         \
    -DWITH_OPENCL=0                                                       \
    -DWITH_OPENNI=0                                                       \
    -DWITH_FFMPEG=1                                                       \
    -DWITH_MATLAB=0                                                       \
    -DWITH_VTK=0                                                          \
    -DWITH_GTK=0                                                          \
    -DINSTALL_C_EXAMPLES=0                                                \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib-$PKG_VERSION/modules"  \
    -DPYTHON_PACKAGES_PATH="${SP_DIR}"                                    \
    -DPYTHON_EXECUTABLE="${PYTHON}"                                       \
    -DPYTHON_INCLUDE_DIR=""                                               \
    -DPYTHON_INCLUDE_DIR="${INC_PYTHON}"                                  \
    -DPYTHON_LIBRARY="${LIB_PYTHON}"                                      \
    -DBUILD_opencv_python2=0                                              \
    -DPYTHON2_EXECUTABLE=""                                               \
    -DPYTHON2_INCLUDE_DIR=""                                              \
    -DPYTHON2_NUMPY_INCLUDE_DIRS=""                                       \
    -DPYTHON2_LIBRARY=""                                                  \
    -DPYTHON_INCLUDE_DIR2=""                                              \
    -DPYTHON2_PACKAGES_PATH=""                                            \
    -DBUILD_opencv_python3=0                                              \
    -DPYTHON3_EXECUTABLE=""                                               \
    -DPYTHON3_NUMPY_INCLUDE_DIRS=""                                       \
    -DPYTHON3_INCLUDE_DIR=""                                              \
    -DPYTHON3_LIBRARY=""                                                  \
    -DPYTHON3_PACKAGES_PATH=""                                            \
    -DBUILD_opencv_python${PY_MAJOR}=1                                    \
    -DPYTHON${PY_MAJOR}_EXECUTABLE=${PYTHON}                              \
    -DPYTHON${PY_MAJOR}_INCLUDE_DIR=${INC_PYTHON}                         \
    -DPYTHON${PY_MAJOR}_NUMPY_INCLUDE_DIRS=${SP_DIR}/numpy/core/include   \
    -DPYTHON${PY_MAJOR}_LIBRARY=${LIB_PYTHON}                             \
    -DPYTHON${PY_MAJOR}_PACKAGES_PATH=${SP_DIR}                           \
    ${CMAKE_OSX_DEPLOYMENT_TARGET}

if [[ ! $? ]]; then
  echo "configure failed with $?"
  exit 1
fi

make -j ${CPU_COUNT}
make install
