#!/bin/bash
set -ex

V4L="1"
OPENVINO="1"

if [[ "${target_platform}" == linux-* ]]; then
    # Looks like there's a bug in Opencv 3.2.0 for building with FFMPEG
    # with GCC opencv/issues/8097
    export CXXFLAGS="$CXXFLAGS -D__STDC_CONSTANT_MACROS"
    OPENMP="-DWITH_OPENMP=1"
fi

if [[ "${target_platform}" == osx-* ]]; then
    # https://conda-forge.org/docs/maintainer/knowledge_base/#newer-c-features-with-old-sdk
    # Address: error: 'path' is unavailable: introduced in macOS 10.15
    export CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

# Compile against Qt6 and build the Qt window backend as a dynamically loaded
# highgui plugin (opencv_highgui_qt) instead of linking it into the highgui
# module (see patches 0005/0006). HIGHGUI_PLUGIN_LIST=qt6 builds the plugin and
# keeps libopencv Qt-free; HIGHGUI_ENABLE_PLUGINS makes highgui load UI backends
# at runtime. A single build then works headless (no qt6 installed) or with GUI
# (when the opencv-qt6 plugin package and qt6 are present).
#
# Qt6 is not available on ppc64le, so there we fall back to a plain headless
# build (no Qt, no plugin) -- equivalent to the old qt_version=none variant.
#
# The opencv_contrib 'cvv' visual-debug module links Qt directly (it is not a
# highgui backend and has no python API), which would pull Qt back into
# libopencv. Disable it (-DBUILD_opencv_cvv=0 below) so libopencv stays Qt-free;
# it was never present in the old headless variant anyway.
if [[ "${target_platform}" == linux-ppc64le ]]; then
    QT="0"
    HIGHGUI_PLUGINS=""
else
    QT="6"
    HIGHGUI_PLUGINS="-DHIGHGUI_ENABLE_PLUGINS=ON -DHIGHGUI_PLUGIN_LIST=qt6"
    # hmaarrfk - 2025/05
    # Qt 6.9 seems to inject the wrong flags here. They don't seem necessary
    # https://github.com/conda-forge/qt-main-feedstock/issues/332
    sed -i.bak '/INTERFACE_COMPILE_DEFINITIONS/d' "${PREFIX}/lib/cmake/Qt6Test/Qt6TestTargets.cmake"
    rm "${PREFIX}/lib/cmake/Qt6Test/Qt6TestTargets.cmake.bak"
fi

if [[ "${target_platform}" == osx-* ]]; then
    V4L="0"
    # hmaarrfk - 2026/01/01
    # SVE2 (Scalable Vector Extension 2) is not supported on macOS/Darwin, even on Apple Silicon.
    # Disable it to prevent compiler crashes when kleidicv tries to compile SVE2-specific code.
    CMAKE_ARGS="${CMAKE_ARGS} -DKLEIDICV_ENABLE_SVE2=OFF"
elif [[ "${target_platform}" == linux-ppc64le ]]; then
    OPENVINO="0"
fi


if [[ "${target_platform}" != "${build_platform}" ]]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DProtobuf_PROTOC_EXECUTABLE=$BUILD_PREFIX/bin/protoc"
    CMAKE_ARGS="${CMAKE_ARGS} -DQT_HOST_PATH=${BUILD_PREFIX}"
fi


export PKG_CONFIG_LIBDIR=$PREFIX/lib

IS_PYPY=$(${PYTHON} -c "import platform; print(int(platform.python_implementation() == 'PyPy'))")

# Build the cv2 module against CPython's stable ABI (abi3) so that a single
# build is compatible with every later python. The recipe only builds on
# python_min (build: skip on non-min), so the running python defines the
# minimum limited-API version, e.g. 3.10 -> 0x030a0000.
PY_LIMITED_API_VERSION=$(${PYTHON} -c "import sys; print('0x%02X%02X0000' % sys.version_info[:2])")

# Install the cv2 loader with paths RELATIVE to the package (LOADER_DIR) rather
# than the absolute build-time site-packages. The abi3 module is built once on
# python_min but installed into other pythons (python3.11, 3.12, ...); an
# absolute path would hard-code "lib/python3.10/..." into config-3.py and break
# the loader on every other python. A relative OPENCV_PYTHON*_INSTALL_PATH makes
# OpenCV emit os.path.join(LOADER_DIR, ...) paths, which relocate correctly.
SP_DIR_RELATIVE=$(${PYTHON} -c "import os; print(os.path.relpath('${SP_DIR}', '${PREFIX}'))")

LIB_PYTHON="${PREFIX}/lib/libpython${PY_VER}${SHLIB_EXT}"
if [[ ${IS_PYPY} == "1" ]]; then
    INC_PYTHON="$PREFIX/include/pypy${PY_VER}"
else
    INC_PYTHON="$PREFIX/include/python${PY_VER}"
fi

# FFMPEG building requires pkgconfig
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig

mkdir -p build
cd build

# Features that are disabled
# WITH_OBSENSOR
# Orbbec seems to be tricky requiring lots of firmware and software to run on OSX
# https://github.com/opencv/opencv/pull/24877
# The comment also looks scary on linux, I'll let some1 who needs it test

cmake -LAH -G "Ninja"                                                     \
    ${CMAKE_ARGS}                                                         \
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
    -DCMAKE_CXX_STANDARD=17                                               \
    -DWITH_AVIF=1                                                         \
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
    -DBUILD_OPENEXR=0                                                     \
    -DWITH_OPENEXR=1                                                      \
    -DBUILD_JPEGXL=0                                                      \
    -DWITH_JPEGXL=1                                                       \
    -DWITH_JASPER=0                                                       \
    -DBUILD_OPENJPEG=0                                                    \
    -DWITH_OPENJPEG=1                                                     \
    -DBUILD_JPEG=0                                                        \
    -DBUILD_WEBP=0                                                        \
    -DWITH_WEBP=1                                                         \
    -DWITH_V4L=$V4L                                                       \
    -DWITH_CUDA=0                                                         \
    -DWITH_CUBLAS=0                                                       \
    -DWITH_OPENCL=0                                                       \
    -DWITH_OPENCLAMDFFT=0                                                 \
    -DWITH_OPENCLAMDBLAS=0                                                \
    -DWITH_OPENCL_D3D11_NV=0                                              \
    -DWITH_OPENVINO=$OPENVINO                                             \
    -DWITH_1394=0                                                         \
    -DWITH_OPENNI=0                                                       \
    -DWITH_HDF5=1                                                         \
    -DWITH_FFMPEG=1                                                       \
    -DWITH_FREETYPE=1                                                     \
    -DWITH_TENGINE=0                                                      \
    -DWITH_GSTREAMER=0                                                    \
    -DWITH_MATLAB=0                                                       \
    -DWITH_TESSERACT=0                                                    \
    -DWITH_VA=0                                                           \
    -DWITH_VA_INTEL=0                                                     \
    -DWITH_VTK=0                                                          \
    -DWITH_GTK=0                                                          \
    -DWITH_QT=$QT                                                         \
    ${HIGHGUI_PLUGINS}                                                    \
    -DBUILD_opencv_cvv=0                                                  \
    -DWITH_GPHOTO2=0                                                      \
    -DWITH_OBSENSOR=0                                                     \
    -DINSTALL_C_EXAMPLES=0                                                \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"               \
    -DCMAKE_SKIP_RPATH:bool=ON                                            \
    -DPYTHON_PACKAGES_PATH=${SP_DIR}                                      \
    -DPYTHON_EXECUTABLE=${PYTHON}                                         \
    -DPYTHON_INCLUDE_DIR=${INC_PYTHON}                                    \
    -DPYTHON_LIBRARY=${LIB_PYTHON}                                        \
    -DOPENCV_SKIP_PYTHON_LOADER=0                                         \
    -DOPENCV_FFMPEG_SKIP_DOWNLOAD=1                                       \
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
    -DPYTHON3_LIMITED_API=ON                                              \
    -DPYTHON3_LIMITED_API_VERSION=${PY_LIMITED_API_VERSION}               \
    -DPYTHON3_EXECUTABLE=${PYTHON}                                        \
    -DPYTHON3_INCLUDE_DIR=${INC_PYTHON}                                   \
    -DPYTHON3_NUMPY_INCLUDE_DIRS=$(python -c 'import numpy;print(numpy.get_include())')  \
    -DPYTHON3_LIBRARY=${LIB_PYTHON}                                       \
    -DPYTHON3_PACKAGES_PATH=${SP_DIR}                                     \
    -DOPENCV_PYTHON3_INSTALL_PATH=${SP_DIR_RELATIVE}                      \
    -DOPENCV_PYTHON_INSTALL_PATH=${SP_DIR_RELATIVE}                       \
    -DBUILD_opencv_python2=0                                              \
    -DPYTHON2_EXECUTABLE=                                                 \
    -DPYTHON2_INCLUDE_DIR=                                                \
    -DPYTHON2_NUMPY_INCLUDE_DIRS=                                         \
    -DPYTHON2_LIBRARY=                                                    \
    -DPYTHON2_PACKAGES_PATH=                                              \
    -DOPENCV_PYTHON2_INSTALL_PATH=                                        \
    ..

ninja install -j${CPU_COUNT}
