#!/bin/bash

mkdir -p build
cd build

set +x
SHORT_OS_STR=$(uname -s)

if [ "${SHORT_OS_STR:0:5}" == "Linux" ]; then
    OPENMP="-DWITH_OPENMP=1"
fi
if [ "${SHORT_OS_STR}" == "Darwin" ]; then
    OPENMP=""
fi

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

cmake -LAH ..                                                  \
    $OPENMP                                                    \
    -DCMAKE_SKIP_RPATH=1                                       \
    -DWITH_EIGEN=1                                             \
    -DBUILD_opencv_apps=0                                      \
    -DBUILD_TESTS=0                                            \
    -DBUILD_DOCS=0                                             \
    -DBUILD_PERF_TESTS=0                                       \
    -DBUILD_ZLIB=0                                             \
    -DZLIB_LIBRARY=$PREFIX/lib/libz$SHLIB_EXT                  \
    -DBUILD_TIFF=0                                             \
    -DBUILD_PNG=0                                              \
    -DBUILD_OPENEXR=1                                          \
    -DBUILD_JASPER=0                                           \
    -DBUILD_JPEG=0                                             \
    -DJPEG_INCLUDE_DIR=$PREFIX/include                         \
    -DJPEG_LIBRARY=$PREFIX/lib/libjpeg$SHLIB_EXT               \
    -DJASPER_INCLUDE_DIR=$PREFIX/include                       \
    -DJASPER_LIBRARY_RELEASE=$PREFIX/lib/libjasper$SHLIB_EXT   \
    -DTIFF_INCLUDE_DIR=$PREFIX/include                         \
    -DTIFF_LIBRARY_RELEASE=$PREFIX/lib/libtiff$SHLIB_EXT       \
    -DPNG_PNG_INCLUDE_DIR=$PREFIX/include                      \
    -DPNG_LIBRARY_RELEASE=$PREFIX/lib/libpng$SHLIB_EXT         \
    -DPYTHON_EXECUTABLE=$PREFIX/bin/python${PY_VER}            \
    -DPYTHON_INCLUDE_PATH=$PREFIX/include/python${PY_VER}      \
    -DPYTHON_LIBRARY=$PREFIX/lib/libpython${PY_VER}$SHLIB_EXT  \
    -DPYTHON_PACKAGES_PATH=$SP_DIR                             \
    -DWITH_CUDA=0                                              \
    -DWITH_OPENCL=0                                            \
    -DWITH_OPENNI=0                                            \
    -DWITH_FFMPEG=1                                            \
    -DCMAKE_INSTALL_PREFIX=$PREFIX

make install -j${CPU_COUNT}
