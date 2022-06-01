#!/usr/bin/env bash

set +ex

# CMake FindPNG seems to look in libpng not libpng16
# https://gitlab.kitware.com/cmake/cmake/blob/master/Modules/FindPNG.cmake#L55
ln -s $PREFIX/include/libpng16 $PREFIX/include/libpng

QT="5"
V4L="1"

if [[ "${target_platform}" == linux-* ]]; then
    # Looks like there's a bug in Opencv 3.2.0 for building with FFMPEG
    # with GCC opencv/issues/8097
    export CXXFLAGS="$CXXFLAGS -D__STDC_CONSTANT_MACROS"

    export CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
    export CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
    OPENMP="-DWITH_OPENMP=1"
fi

if [[ "${target_platform}" == osx-* ]]; then
    QT="0"
    V4L="0"
elif [[ "${target_platform}" == linux-ppc64le ]]; then
    QT="0"
fi


if [[ "${target_platform}" != "${build_platform}" ]]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
fi


export PKG_CONFIG_LIBDIR=$PREFIX/lib

IS_PYPY=$(${PYTHON} -c "import platform; print(int(platform.python_implementation() == 'PyPy'))")

# Python 3.8 now combines the "m" and the "no m" builds in 1.
if [ ${PY_VER} == "3.6" ] || [ ${PY_VER} == "3.7" ]; then
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}${SHLIB_EXT}m"
    INC_PYTHON="$PREFIX/include/python${PY_VER}m"
else
    LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}${SHLIB_EXT}"
    if [[ ${IS_PYPY} == "1" ]]; then
        INC_PYTHON="$PREFIX/include/pypy${PY_VER}"
    else
        INC_PYTHON="$PREFIX/include/python${PY_VER}"
    fi
fi

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

mkdir -p build
cd build
cmake ${CMAKE_ARGS} -LAH -G "Ninja"                                       \
    -DCMAKE_BUILD_TYPE="Release"                                          \
    -DCMAKE_PREFIX_PATH=${PREFIX}                                         \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}                                      \
    -DCMAKE_INSTALL_LIBDIR="lib"                                          \
    -DOPENCV_DOWNLOAD_TRIES=1\;2\;3\;4\;5                                 \
    -DOPENCV_DOWNLOAD_PARAMS=INACTIVITY_TIMEOUT\;30\;TIMEOUT\;180\;SHOW_PROGRESS \
    -DOPENCV_GENERATE_PKGCONFIG=ON                                        \
    -DENABLE_CONFIG_VERIFICATION=ON                                       \
    -DENABLE_PRECOMPILED_HEADERS=OFF                                      \
    $OPENMP                                                               \
    -DWITH_LAPACK=1                                                       \
    -DLAPACK_LAPACKE_H=lapacke.h                                          \
    -DLAPACK_CBLAS_H=cblas.h                                              \
    -DLAPACK_LIBRARIES=lapack\;cblas                                      \
    -DWITH_EIGEN=1                                                        \
    -DBUILD_TESTS=0                                                       \
    -DBUILD_DOCS=0                                                        \
    -DBUILD_PERF_TESTS=0                                                  \
    -DBUILD_ZLIB=0                                                        \
    -DBUILD_TIFF=0                                                        \
    -DBUILD_PNG=0                                                         \
    -DWITH_PROTOBUF=1                                                     \
    -DBUILD_PROTOBUF=0                                                    \
    -DPROTOBUF_UPDATE_FILES=1                                             \
    -DBUILD_OPENEXR=1                                                     \
    -DBUILD_JASPER=0                                                      \
    -DWITH_JASPER=1                                                       \
    -DWITH_OPENJPEG=0                                                     \
    -DBUILD_JPEG=0                                                        \
    -DWITH_V4L=$V4L                                                       \
    -DWITH_CUDA=0                                                         \
    -DWITH_CUBLAS=0                                                       \
    -DWITH_OPENCL=0                                                       \
    -DWITH_OPENCLAMDFFT=0                                                 \
    -DWITH_OPENCLAMDBLAS=0                                                \
    -DWITH_OPENCL_D3D11_NV=0                                              \
    -DWITH_1394=0                                                         \
    -DWITH_OPENNI=0                                                       \
    -DWITH_FFMPEG=1                                                       \
    -DWITH_TENGINE=0                                                      \
    -DWITH_GSTREAMER=0                                                    \
    -DWITH_MATLAB=0                                                       \
    -DWITH_TESSERACT=0                                                    \
    -DWITH_VA=0                                                           \
    -DWITH_VA_INTEL=0                                                     \
    -DWITH_VTK=0                                                          \
    -DWITH_GTK=0                                                          \
    -DWITH_QT=$QT                                                         \
    -DWITH_GPHOTO2=0                                                      \
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
    -DJPEG_INCLUDE_DIR=${PREFIX}/include                                  \
    -DTIFF_INCLUDE_DIR=${PREFIX}/include                                  \
    -DPNG_PNG_INCLUDE_DIR=${PREFIX}/include                               \
    -DPROTOBUF_INCLUDE_DIR=${PREFIX}/include                              \
    -DPROTOBUF_LIBRARIES=${PREFIX}/lib                                    \
    -DOPENCV_ENABLE_PKG_CONFIG=1                                          \
    -DOPENCV_PYTHON_PIP_METADATA_INSTALL=ON                               \
    -DOPENCV_PYTHON_PIP_METADATA_INSTALLER:STRING="conda"                 \
    -DBUILD_opencv_python3=1                                              \
    -DPYTHON3_EXECUTABLE=${PYTHON}                                        \
    -DPYTHON3_INCLUDE_DIR=${INC_PYTHON}                                   \
    -DPYTHON3_NUMPY_INCLUDE_DIRS=$(python -c 'import numpy;print(numpy.get_include())')  \
    -DPYTHON3_LIBRARY=${LIB_PYTHON}                                       \
    -DPYTHON3_PACKAGES_PATH=${SP_DIR}                                     \
    -DOPENCV_PYTHON3_INSTALL_PATH=${SP_DIR}                               \
    -DBUILD_opencv_python2=0                                              \
    -DPYTHON2_EXECUTABLE=                                                 \
    -DPYTHON2_INCLUDE_DIR=                                                \
    -DPYTHON2_NUMPY_INCLUDE_DIRS=                                         \
    -DPYTHON2_LIBRARY=                                                    \
    -DPYTHON2_PACKAGES_PATH=                                              \
    -DOPENCV_PYTHON2_INSTALL_PATH=                                        \
    ..

ninja install -v -j${CPU_COUNT}
