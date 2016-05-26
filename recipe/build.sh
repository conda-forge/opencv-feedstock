#!/bin/bash

SHORT_OS_STR=$(uname -s)

if [ "${SHORT_OS_STR:0:5}" == "Linux" ]; then
    DYNAMIC_EXT="so"
    OPENMP="-DWITH_OPENMP=1"
    IS_OSX=0
    # There's a bug with CMake at the moment whereby it can't download
    # using HTTPS - so we use curl to download the IPP library
    # mkdir -p $SRC_DIR/3rdparty/ippicv/downloads/linux-808b791a6eac9ed78d32a7666804320e
    # curl -L https://raw.githubusercontent.com/Itseez/opencv_3rdparty/81a676001ca8075ada498583e4166079e5744668/ippicv/ippicv_linux_20151201.tgz -o $SRC_DIR/3rdparty/ippicv/downloads/linux-808b791a6eac9ed78d32a7666804320e/ippicv_linux_20151201.tgz
fi
if [ "${SHORT_OS_STR}" == "Darwin" ]; then
    DYNAMIC_EXT="dylib"
    OPENMP=""
    # For some reason OpenCV just won't see hdf5.h without updating the CFLAGS
    export CFLAGS="$CFLAGS -I$PREFIX/include"
    export CXXFLAGS="$CXXFLAGS -I$PREFIX/include"
    # Require C++11
    export MACOSX_DEPLOYMENT_TARGET="10.7"
fi

if [ $PY3K -eq 1 ]; then
    PY_VER_M="${PY_VER}m"
    OCV_PYTHON="-DBUILD_opencv_python3=1 -DPYTHON3_EXECUTABLE=$PYTHON -DPYTHON3_INCLUDE_DIR=$PREFIX/include/python${PY_VER_M} -DPYTHON3_LIBRARY=${PREFIX}/lib/libpython${PY_VER_M}.${DYNAMIC_EXT} -DPYTHON3_PACKAGES_PATH=$SP_DIR" 
else
    OCV_PYTHON="-DBUILD_opencv_python2=1 -DPYTHON2_EXECUTABLE=$PYTHON -DPYTHON2_INCLUDE_DIR=$PREFIX/include/python${PY_VER} -DPYTHON2_LIBRARY=${PREFIX}/lib/libpython${PY_VER}.${DYNAMIC_EXT} -DPYTHON_INCLUDE_DIR2=$PREFIX/include/python${PY_VER} -DPYTHON2_PACKAGES_PATH=$SP_DIR"
fi

git clone https://github.com/Itseez/opencv_contrib --single-branch --branch $PKG_VERSION --depth 1

mkdir build
cd build

cmake .. -LAH                                                \
    $OPENMP                                                  \
    $OCV_PYTHON                                              \
    -DWITH_EIGEN=1                                           \
    -DBUILD_TESTS=0                                          \
    -DBUILD_DOCS=0                                           \
    -DBUILD_PERF_TESTS=0                                     \
    -DBUILD_ZLIB=0                                           \
    -DZLIB_LIBRARY_RELEASE=$PREFIX/lib/libz.$DYNAMIC_EXT     \
    -DZLIB_INCLUDE_DIR=$PREFIX/include                       \
    -DHDF5_z_LIBRARY_RELEASE=$PREFIX/lib/libz.$DYNAMIC_EXT   \
    -DBUILD_TIFF=0                                           \
    -DBUILD_PNG=0                                            \
    -DBUILD_OPENEXR=1                                        \
    -DBUILD_JASPER=0                                         \
    -DBUILD_JPEG=0                                           \
    -DWITH_CUDA=0                                            \
    -DWITH_OPENCL=0                                          \
    -DWITH_OPENNI=0                                          \
    -DWITH_FFMPEG=0                                          \
    -DWITH_VTK=0                                             \
    -DINSTALL_C_EXAMPLES=0                                   \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"  \
    -DCMAKE_BUILD_TYPE="Release"                             \
    -DCMAKE_SKIP_RPATH:bool=ON                               \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

make
make install
