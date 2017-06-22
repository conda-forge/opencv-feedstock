#!/usr/bin/env bash

set +x
SHORT_OS_STR=$(uname -s)

QT="5"
if [ "${SHORT_OS_STR:0:5}" == "Linux" ]; then
    OPENMP="-DWITH_OPENMP=1"
    # Looks like there's a bug in Opencv 3.2.0 for building with FFMPEG
    # with GCC opencv/issues/8097
    export CXXFLAGS="$CXXFLAGS -D__STDC_CONSTANT_MACROS"
fi
if [ "${SHORT_OS_STR}" == "Darwin" ]; then
    OPENMP=""
    QT="0"
fi

curl -L -O "https://github.com/opencv/opencv_contrib/archive/$PKG_VERSION.tar.gz"
test `openssl sha256 $PKG_VERSION.tar.gz | awk '{print $2}'` = "1e2bb6c9a41c602904cc7df3f8fb8f98363a88ea564f2a087240483426bf8cbe"
tar -zxf $PKG_VERSION.tar.gz

# Contrib has patches that need to be applied
# https://github.com/opencv/opencv_contrib/issues/919
patch -p0 < $RECIPE_DIR/opencv_contrib_freetype.patch

mkdir -p build
cd build

if [ $PY3K -eq 1 ]; then
    PY_MAJOR=3
    PY_UNSET_MAJOR=2
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}m${SHLIB_EXT}"
    INC_PYTHON="$PREFIX/include/python${PY_VER}m"
else
    PY_MAJOR=2
    PY_UNSET_MAJOR=3
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}${SHLIB_EXT}"
    INC_PYTHON="$PREFIX/include/python${PY_VER}"
fi


PYTHON_SET_FLAG="-DBUILD_opencv_python${PY_MAJOR}=1"
PYTHON_SET_EXE="-DPYTHON${PY_MAJOR}_EXECUTABLE=${PYTHON}"
PYTHON_SET_INC="-DPYTHON${PY_MAJOR}_INCLUDE_DIR=${INC_PYTHON} "
PYTHON_SET_NUMPY="-DPYTHON${PY_MAJOR}_NUMPY_INCLUDE_DIRS=${SP_DIR}/numpy/core/include"
PYTHON_SET_LIB="-DPYTHON${PY_MAJOR}_LIBRARY=${LIB_PYTHON}"
PYTHON_SET_SP="-DPYTHON${PY_MAJOR}_PACKAGES_PATH=${SP_DIR}"

PYTHON_UNSET_FLAG="-DBUILD_opencv_python${PY_UNSET_MAJOR}=0"
PYTHON_UNSET_EXE="-DPYTHON${PY_UNSET_MAJOR}_EXECUTABLE="
PYTHON_UNSET_INC="-DPYTHON${PY_UNSET_MAJOR}_INCLUDE_DIR="
PYTHON_UNSET_NUMPY="-DPYTHON${PY_UNSET_MAJOR}_NUMPY_INCLUDE_DIRS="
PYTHON_UNSET_LIB="-DPYTHON${PY_UNSET_MAJOR}_LIBRARY="
PYTHON_UNSET_SP="-DPYTHON${PY_UNSET_MAJOR}_PACKAGES_PATH="

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

# For some reason OpenCV just won't see hdf5.h without updating the CFLAGS
export CFLAGS="$CFLAGS -I$PREFIX/include"
export CXXFLAGS="$CXXFLAGS -I$PREFIX/include"

cmake .. -LAH                                                             \
    $OPENMP                                                               \
    -DOpenBLAS=1                                                          \
    -DOpenBLAS_INCLUDE_DIR=$PREFIX/include                                \
    -DOpenBLAS_LIB=$PREFIX/lib/libopenblas$SHLIB_EXT                      \
    -DWITH_EIGEN=1                                                        \
    -DBUILD_TESTS=0                                                       \
    -DBUILD_DOCS=0                                                        \
    -DBUILD_PERF_TESTS=0                                                  \
    -DBUILD_ZLIB=0                                                        \
    -DFFMPEG_INCLUDE_DIR=$PREFIX/include                                  \
    -DFFMPEG_LIB_DIR=$PREFIX/lib                                          \
    -DHDF5_DIR=$PREFIX                                                    \
    -DHDF5_INCLUDE_DIRS=$PREFIX/include                                   \
    -DHDF5_C_LIBRARY_hdf5=$PREFIX/lib/libhdf5$SHLIB_EXT                   \
    -DHDF5_C_LIBRARY_z=$PREFIX/lib/libz$SHLIB_EXT                         \
    -DFREETYPE_INCLUDE_DIRS=$PREFIX/include/freetype2                     \
    -DFREETYPE_LIBRARIES=$PREFIX/lib/libfreetype$SHLIB_EXT                \
    -DPNG_LIBRARY_RELEASE=$PREFIX/lib/libpng$SHLIB_EXT                    \
    -DPNG_INCLUDE_DIRS=$PREFIX/include                                    \
    -DJPEG_INCLUDE_DIR=$PREFIX/include                                    \
    -DJPEG_LIBRARY=$PREFIX/lib/libjpeg$SHLIB_EXT                          \
    -DTIFF_INCLUDE_DIR=$PREFIX/include                                    \
    -DTIFF_LIBRARY=$PREFIX/lib/libtiff$SHLIB_EXT                          \
    -DJASPER_INCLUDE_DIR=$PREFIX/include                                  \
    -DJASPER_LIBRARY_RELEASE=$PREFIX/lib/libjasper$SHLIB_EXT              \
    -DWEBP_INCLUDE_DIR=$PREFIX/include                                    \
    -DWEBP_LIBRARY=$PREFIX/lib/libwebp$SHLIB_EXT                          \
    -DHARFBUZZ_INCLUDE_DIRS=$PREFIX/include/harfbuzz                      \
    -DHARFBUZZ_LIBRARIES=$PREFIX/lib/libharfbuzz$SHLIB_EXT                \
    -DZLIB_LIBRARY_RELEASE=$PREFIX/lib/libz$SHLIB_EXT                     \
    -DZLIB_INCLUDE_DIR=$PREFIX/include                                    \
    -DHDF5_z_LIBRARY_RELEASE=$PREFIX/lib/libz$SHLIB_EXT                   \
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
    -DCMAKE_BUILD_TYPE="Release"                                          \
    -DCMAKE_SKIP_RPATH:bool=ON                                            \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                                        \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                      \
    -DPYTHON_EXECUTABLE=${PYTHON}                                         \
    -DPYTHON_INCLUDE_DIR=${INC_PYTHON}                                    \
    -DPYTHON_LIBRARY=${LIB_PYTHON}                                        \
    $PYTHON_SET_FLAG                                                      \
    $PYTHON_SET_EXE                                                       \
    $PYTHON_SET_INC                                                       \
    $PYTHON_SET_NUMPY                                                     \
    $PYTHON_SET_LIB                                                       \
    $PYTHON_SET_SP                                                        \
    $PYTHON_UNSET_FLAG                                                    \
    $PYTHON_UNSET_EXE                                                     \
    $PYTHON_UNSET_INC                                                     \
    $PYTHON_UNSET_NUMPY                                                   \
    $PYTHON_UNSET_LIB                                                     \
    $PYTHON_UNSET_SP

make -j8
make install
