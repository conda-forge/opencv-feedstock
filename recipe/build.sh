#!/usr/bin/env bash

set +x
SHORT_OS_STR=$(uname -s)

QT="5"
GSTREAMER="1"
if [ "${SHORT_OS_STR:0:5}" == "Linux" ]; then
    OPENMP="-DWITH_OPENMP=1"
    # Looks like there's a bug in Opencv 3.2.0 for building with FFMPEG
    # with GCC opencv/issues/8097
    export CXXFLAGS="$CXXFLAGS -D__STDC_CONSTANT_MACROS"

    export CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
    export CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

    export LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
fi
if [ "${SHORT_OS_STR}" == "Darwin" ]; then
    OPENMP=""
    QT="0"
    GSTREAMER="0"
    # The old OSX compilers don't know what to do with AVX instructions
    # Therefore, we specify what CPU dispatch operations we want explicitely
    # for OSX..
    # I took this line from the default build flags that get spewed after
    # a successful call to cmake without the parameter specified
    # The default flag as of OpenCV 3.4.4 are:
    # CPU_DISPATCH:STRING=SSE4_1;SSE4_2;AVX;FP16;AVX2;AVX512_SKX
    CPU_DISPATCH_FLAGS="-DCPU_DISPATCH=SSE4_1;SSE4_2;AVX;FP16"
fi

CMAKE_TOOLCHAIN_CMD_FLAGS=""
if [ "$c_compiler" = clang ]; then
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_AR=${AR}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_LINKER=${LD}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_NM=${NM}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_RANLIB=${RANLIB}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_STRIP=${STRIP}"
elif [ "$c_compiler" = gcc ]; then
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_AR=${AR}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_LINKER=${LD}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_NM=${NM}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_OBJCOPY=${OBJCOPY}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_OBJDUMP=${OBJDUMP}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_RANLIB=${RANLIB}"
    CMAKE_TOOLCHAIN_CMD_FLAGS="${CMAKE_TOOLCHAIN_CMD_FLAGS} -DCMAKE_STRIP=${STRIP}"
fi

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
PYTHON_SET_INSTALL="-DOPENCV_PYTHON${PY_MAJOR}_INSTALL_PATH=${SP_DIR}"

PYTHON_UNSET_FLAG="-DBUILD_opencv_python${PY_UNSET_MAJOR}=0"
PYTHON_UNSET_EXE="-DPYTHON${PY_UNSET_MAJOR}_EXECUTABLE="
PYTHON_UNSET_INC="-DPYTHON${PY_UNSET_MAJOR}_INCLUDE_DIR="
PYTHON_UNSET_NUMPY="-DPYTHON${PY_UNSET_MAJOR}_NUMPY_INCLUDE_DIRS="
PYTHON_UNSET_LIB="-DPYTHON${PY_UNSET_MAJOR}_LIBRARY="
PYTHON_UNSET_SP="-DPYTHON${PY_UNSET_MAJOR}_PACKAGES_PATH="
PYTHON_UNSET_INSTALL="-DOPENCV_PYTHON${PY_UNSET_MAJOR}_INSTALL_PATH=${SP_DIR}"

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

cmake -LAH -G "Ninja"                                                     \
    -DCMAKE_BUILD_TYPE="Release"                                          \
    -DCMAKE_PREFIX_PATH=${PREFIX}                                         \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}                                      \
    -DCMAKE_INSTALL_LIBDIR="lib"                                          \
    $CMAKE_TOOLCHAIN_CMD_FLAGS                                            \
    -DOPENCV_GENERATE_PKGCONFIG=ON                                        \
    $CPU_DISPATCH_FLAGS                                                   \
    $OPENMP                                                               \
    -DLAPACK_LIBRARIES="-llapacke -llapack -lcblas -lblas"                \
    -DWITH_LAPACK=1                                                       \
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
    -DWITH_V4L=0                                                          \
    -DWITH_CUDA=0                                                         \
    -DWITH_CUBLAS=0                                                       \
    -DWITH_OPENCL=0                                                       \
    -DWITH_OPENNI=0                                                       \
    -DWITH_FFMPEG=1                                                       \
    -DWITH_GSTREAMER=$GSTREAMER                                           \
    -DWITH_MATLAB=0                                                       \
    -DWITH_VTK=0                                                          \
    -DWITH_QT=$QT                                                         \
    -DWITH_GPHOTO2=0                                                      \
    -DVIDEOIO_PLUGIN_LIST=ffmpeg,gstreamer                                \
    -DINSTALL_C_EXAMPLES=0                                                \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"               \
    -DCMAKE_SKIP_RPATH:bool=ON                                            \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                      \
    -DPYTHON_EXECUTABLE=${PYTHON}                                         \
    -DPYTHON_INCLUDE_DIR=${INC_PYTHON}                                    \
    -DPYTHON_LIBRARY=${LIB_PYTHON}                                        \
    -DOPENCV_SKIP_PYTHON_LOADER=1                                         \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include                                  \
    -DZLIB_LIBRARY_RELEASE=${PREFIX}/lib/libz${SHLIB_EXT}                 \
    -DPNG_INCLUDE_DIR=${PREFIX}/include                                   \
    -DPROTOBUF_INCLUDE_DIR=${PREFIX}/include                              \
    -DPROTOBUF_LIBRARIES=${PREFIX}/lib                                    \
    $PYTHON_SET_FLAG                                                      \
    $PYTHON_SET_EXE                                                       \
    $PYTHON_SET_INC                                                       \
    $PYTHON_SET_NUMPY                                                     \
    $PYTHON_SET_LIB                                                       \
    $PYTHON_SET_SP                                                        \
    $PYTHON_SET_INSTALL                                                   \
    $PYTHON_UNSET_FLAG                                                    \
    $PYTHON_UNSET_EXE                                                     \
    $PYTHON_UNSET_INC                                                     \
    $PYTHON_UNSET_NUMPY                                                   \
    $PYTHON_UNSET_LIB                                                     \
    $PYTHON_UNSET_SP                                                      \
    $PYTHON_UNSET_INSTALL                                                 \
    ..

ninja install
