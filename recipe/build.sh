#!/usr/bin/env bash

set +x

QT="5"
if test `uname` = "Linux"
then
    OPENMP="-DWITH_OPENMP=1"
else
    OPENMP=""
    QT="0"
fi

curl -L -O "https://github.com/opencv/opencv_contrib/archive/$PKG_VERSION.tar.gz"
test `openssl sha256 $PKG_VERSION.tar.gz | awk '{print $2}'` = "e94acf39cd4854c3ef905e06516e5f74f26dddfa6477af89558fb40a57aeb444"
tar -zxf $PKG_VERSION.tar.gz

# Contrib has patches that need to be applied
# https://github.com/opencv/opencv_contrib/issues/919
# patch -p0 < $RECIPE_DIR/opencv_contrib_freetype.patch

mkdir build && cd build

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

cmake -LAH                                                                \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                                           \
    $OPENMP                                                               \
    -DOpenBLAS=1                                                          \
    -DWITH_EIGEN=1                                                        \
    -DBUILD_TESTS=0                                                       \
    -DBUILD_DOCS=0                                                        \
    -DBUILD_PERF_TESTS=0                                                  \
    -DBUILD_ZLIB=0                                                        \
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
    -DWITH_QT=$QT                                                         \
    -DWITH_GPHOTO2=0                                                      \
    -DINSTALL_C_EXAMPLES=0                                                \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib-$PKG_VERSION/modules"  \
    -DCMAKE_BUILD_TYPE=Release                                            \
    -DCMAKE_SKIP_RPATH=ON                                                 \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                      \
    ..

make install -j8
