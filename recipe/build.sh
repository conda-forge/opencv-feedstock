#!/bin/bash

# We install two local pythons so that we can build everything at once.
# The 2nd Python 3 variant does of course cause us problems that we hack
# around in install-py-opencv.sh, still better than building all of libopencv
# 6 times instead of twice (3 * python, 2 * hdf5).
conda create -yp ${PWD}/py2 --override-channels -c https://repo.continuum.io/pkgs/main python=2.7 numpy=1.9
conda create -yp ${PWD}/py3 --override-channels -c https://repo.continuum.io/pkgs/main python=3.6 numpy=1.9

declare -a CMAKE_EXTRA_ARGS
if [[ ${target_platform} =~ linux-* ]]; then
  DYNAMIC_EXT=so
  # Compile with C++11 not C++17 standard
  CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
  CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
elif [[ ${target_platform} == osx-64 ]]; then
  DYNAMIC_EXT=dylib
  CMAKE_EXTRA_ARGS+=(-DCMAKE_OSX_SYSROOT=${CONDA_BUILD_SYSROOT})
fi

mkdir build
cd build

if [[ ! -f Makefile ]]; then

  cmake .. -LAH                                                             \
    -DCMAKE_BUILD_TYPE="Release"                                            \
    -DCMAKE_INSTALL_PREFIX=${PREFIX}                                        \
    -DCMAKE_INSTALL_LIBDIR=lib                                              \
    -DCMAKE_SKIP_RPATH=ON                                                   \
    -DCMAKE_AR="${AR}"                                                      \
    -DCMAKE_LINKER="${LD}"                                                  \
    -DCMAKE_NM="${NM}"                                                      \
    -DCMAKE_OBJCOPY="${OBJCOPY}"                                            \
    -DCMAKE_OBJDUMP="${OBJDUMP}"                                            \
    -DCMAKE_RANLIB="${RANLIB}"                                              \
    -DCMAKE_STRIP="${STRIP}"                                                \
    -DWITH_OPENMP=1                                                         \
    -DWITH_EIGEN=1                                                          \
    -DBUILD_TESTS=0                                                         \
    -DBUILD_DOCS=0                                                          \
    -DBUILD_PERF_TESTS=0                                                    \
    -DBUILD_ZLIB=0                                                          \
    -DZLIB_LIBRARY_RELEASE=${PREFIX}/lib/libz.${DYNAMIC_EXT}                \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include                                    \
    -DPNG_INCLUDE_DIR=${PREFIX}/include                                     \
    -DPNG_LIBRARY_RELEASE=${PREFIX}/lib/libpng.${DYNAMIC_EXT}               \
    -DBUILD_LIBPROTOBUF_FROM_SOURCES=0                                      \
    -DBUILD_PROTOBUF=0                                                      \
    -DPROTOBUF_INCLUDE_DIR=${PREFIX}/include                                \
    -DPROTOBUF_LIBRARIES=${PREFIX}/lib                                      \
    -DBUILD_TIFF=0                                                          \
    -DBUILD_PNG=0                                                           \
    -DBUILD_OPENEXR=1                                                       \
    -DBUILD_JASPER=0                                                        \
    -DBUILD_JPEG=0                                                          \
    -DWITH_CUDA=0                                                           \
    -DWITH_OPENCL=0                                                         \
    -DWITH_OPENNI=0                                                         \
    -DWITH_FFMPEG=1                                                         \
    -DWITH_MATLAB=0                                                         \
    -DWITH_VTK=0                                                            \
    -DWITH_GTK=0                                                            \
    -DINSTALL_C_EXAMPLES=0                                                  \
    -DBUILD_opencv_python2=1                                                \
    -DPYTHON2_EXECUTABLE=${SRC_DIR}/py2/bin/python                          \
    -DPYTHON2_INCLUDE_DIR=${SRC_DIR}/py2/include/python2.7                  \
    -DPYTHON2_NUMPY_INCLUDE_DIRS=${SRC_DIR}/py2/lib/python2.7/site-packages/numpy/core/include   \
    -DPYTHON2_LIBRARY=${SRC_DIR}/py2/lib/libpython2.7m.${DYNAMIC_EXT}       \
    -DPYTHON2_PACKAGES_PATH=${SRC_DIR}/py2/lib/python2.7/site-packages      \
    -DBUILD_opencv_python3=1                                                \
    -DPYTHON3_EXECUTABLE=${SRC_DIR}/py3/bin/python                          \
    -DPYTHON3_INCLUDE_DIR=${SRC_DIR}/py3/include/python3.6m                 \
    -DPYTHON3_NUMPY_INCLUDE_DIRS=${SRC_DIR}/py3/lib/python3.6/site-packages/numpy/core/include   \
    -DPYTHON3_LIBRARY=${SRC_DIR}/py3/lib/libpython3.6m.${DYNAMIC_EXT}       \
    -DPYTHON3_PACKAGES_PATH=${SRC_DIR}/py3/lib/python3.6/site-packages      \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib-${PKG_VERSION}/modules"  \
    "${CMAKE_EXTRA_ARGS[@]}"

  if [[ ! $? ]]; then
    echo "configure failed with $?"
    exit 1
  fi

fi

make -j${CPU_COUNT} ${VERBOSE_CM}
