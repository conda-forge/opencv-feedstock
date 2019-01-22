#!/bin/bash

PYTHON_INTERPS=""
for _PY_VER in 2.7 3.6 3.7; do
  conda create -yp ${PWD}/py${_PY_VER} --override-channels -c https://repo.continuum.io/pkgs/main python=${_PY_VER} numpy=1.11 pylint flake8 || exit 1
  if [[ ${PYTHON_INTERPS} ]]; then
    PYTHON_INTERPS="${PYTHON_INTERPS};${PWD}/py${_PY_VER}/bin/python"
  else
    PYTHON_INTERPS="${PWD}/py${_PY_VER}/bin/python"
  fi
done

# Make sure shared libs are not found:
if [[ ${target_platform} =~ .*linux.* ]]; then
  rm -rf ${PREFIX}/lib/*protobuf*.so*
else
  rm -rf ${PREFIX}/lib/*protobuf*.dylib*
fi

declare -a CMAKE_EXTRA_ARGS
if [[ ${target_platform} =~ linux-* ]]; then
  DYNAMIC_EXT=so
  # Compile with C++11 not C++17 standard
  CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
  CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
  LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
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
    -DOpenCV_INSTALL_BINARIES_PREFIX=""                                     \
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
    -DPYTHON_DEFAULT_EXECUTABLE="${SYS_PYTHON}"                             \
    -DPYTHON_NATIVE_INTERPRETERS="${PYTHON_INTERPS}"                        \
    -DINSTALL_PYTHON_EXAMPLES=1                                             \
    -DENABLE_PYLINT=1                                                       \
    -DENABLE_FLAKE8=1                                                       \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib-${PKG_VERSION}/modules"  \
    "${CMAKE_EXTRA_ARGS[@]}"

  if [[ ! $? ]]; then
    echo "configure failed with $?"
    exit 1
  fi

fi

make -j${CPU_COUNT} ${VERBOSE_CM}
