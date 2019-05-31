#!/bin/bash

# The horror that is:
cp ~/conda/share_cmake-3.12_Modules_FindPythonLibs.cmake ${BUILD_PREFIX}/share/cmake-3.12/Modules/FindPythonLibs.cmake

DEBUG_CMAKE_BUILD_SYSTEM=yes
declare -a CMAKE_DEBUG_ARGS
if [[ ${DEBUG_CMAKE_BUILD_SYSTEM} == yes ]]; then
#  CMAKE_DEBUG_ARGS+=("--debug-trycompile")
#  CMAKE_DEBUG_ARGS+=("-Wdev")
#  CMAKE_DEBUG_ARGS+=("--debug-output")
#  CMAKE_DEBUG_ARGS+=("--trace")
  CMAKE_DEBUG_ARGS+=("-DOPENCV_CMAKE_DEBUG_MESSAGES=1")
fi

declare -a PYTHON_CMAKE_ARGS
if [[ ${OPENCV_USE_N_PYTHON_PATCH} == 1 ]]; then
  PYTHON_INTERPS=""
  for _PY_VER in 2.7 3.6 3.7; do
    conda create -yp ${PWD}/py${_PY_VER} --override-channels -c https://repo.continuum.io/pkgs/main python=${_PY_VER} numpy=1.11 pylint flake8 || exit 1
    if [[ ${PYTHON_INTERPS} ]]; then
      PYTHON_INTERPS="${PYTHON_INTERPS};${PWD}/py${_PY_VER}/bin/python"
    else
      PYTHON_INTERPS="${PWD}/py${_PY_VER}/bin/python"
    fi
  done
  PYTHON_CMAKE_ARGS+=(-DPYTHON_NATIVE_INTERPRETERS="${PYTHON_INTERPS}")
else
  for _PY_VER in 2.7 3.7; do
    conda create -yp ${PWD}/py${_PY_VER} --override-channels -c https://repo.continuum.io/pkgs/main python=${_PY_VER} numpy=1.11 pylint flake8 || exit 1
    _PY_VER_MAJ=${_PY_VER%%.*}
    PYTHON_CMAKE_ARGS+=(-DBUILD_opencv_python${_PY_VER_MAJ}=ON)
    PYTHON_CMAKE_ARGS+=(-DPYTHON${_PY_VER_MAJ}_EXECUTABLE=${PWD}/py${_PY_VER}/bin/python)
    if [[ ${_PY_VER} == 2.7 ]]; then
      PYTHON_CMAKE_ARGS+=(-DPYTHON${_PY_VER_MAJ}_INCLUDE_DIR=${PWD}/py${_PY_VER}/include/python${_PY_VER})
    else
      PYTHON_CMAKE_ARGS+=(-DPYTHON${_PY_VER_MAJ}_INCLUDE_DIR=${PWD}/py${_PY_VER}/include/python${_PY_VER}m)
    fi
    PYTHON_CMAKE_ARGS+=(-DPYTHON${_PY_VER_MAJ}_NUMPY_INCLUDE_DIRS=${PWD}/py${_PY_VER}/lib/python${_PY_VER}/site-packages/numpy/core/include)
    PYTHON_CMAKE_ARGS+=(-DPYTHON${_PY_VER_MAJ}_LIBRARY=${PWD}/py${_PY_VER}/lib/libpython${_PY_VER}m${SHLIB_EXT})
    PYTHON_CMAKE_ARGS+=(-DPYTHON${_PY_VER_MAJ}_PACKAGES_PATH=${PWD}/py${_PY_VER}/lib/python${_PY}/site-packages)
  done
fi
echo "PYTHON_CMAKE_ARGS="
echo "${PYTHON_CMAKE_ARGS[@]}"

# Make sure shared libs are not found:
if [[ ${target_platform} =~ .*linux.* ]]; then
  rm -rf ${PREFIX}/lib/*protobuf*.so*
else
  rm -rf ${PREFIX}/lib/*protobuf*.dylib*
fi

declare -a CMAKE_EXTRA_ARGS
if [[ ${target_platform} =~ linux-* ]]; then
  # Compile with C++11 not C++17 standard
  CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
  CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"
  LDFLAGS="${LDFLAGS} -Wl,-rpath-link,${PREFIX}/lib"
elif [[ ${target_platform} == osx-64 ]]; then
  CMAKE_EXTRA_ARGS+=(-DCMAKE_OSX_SYSROOT=${CONDA_BUILD_SYSROOT})
fi

mkdir build
cd build

if [[ ! -f Makefile ]]; then

#    -DPROTOBUF_INCLUDE_DIR=${PREFIX}/include                                \
#    -DPROTOBUF_LIBRARIES=${PREFIX}/lib                                      \


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
    -DOPENCV_DOWNLOAD_PATH="${SYS_PREFIX}"/conda-bld/src_cache              \
    -DWITH_OPENMP=1                                                         \
    -DWITH_EIGEN=1                                                          \
    -DBUILD_TESTS=0                                                         \
    -DBUILD_DOCS=0                                                          \
    -DBUILD_PERF_TESTS=0                                                    \
    -DBUILD_ZLIB=0                                                          \
    -DZLIB_LIBRARY_RELEASE=${PREFIX}/lib/libz${SHLIB_EXT}                   \
    -DZLIB_INCLUDE_DIR=${PREFIX}/include                                    \
    -DPNG_INCLUDE_DIR=${PREFIX}/include                                     \
    -DPNG_LIBRARY_RELEASE=${PREFIX}/lib/libpng${SHLIB_EXT}                  \
    -DBUILD_LIBPROTOBUF_FROM_SOURCES=0                                      \
    -DBUILD_PROTOBUF=0                                                      \
    -DBUILD_TIFF=0                                                          \
    -DBUILD_PNG=0                                                           \
    -DBUILD_OPENEXR=ON                                                      \
    -DBUILD_JASPER=0                                                        \
    -DBUILD_JPEG=0                                                          \
    -DWITH_CUDA=OFF                                                         \
    -DWITH_OPENCL=OFF                                                       \
    -DWITH_OPENNI=OFF                                                       \
    -DWITH_FFMPEG=ON                                                        \
    -DWITH_MATLAB=OFF                                                       \
    -DWITH_VTK=OFF                                                          \
    -DWITH_GTK=OFF                                                          \
    -DINSTALL_C_EXAMPLES=OFF                                                \
    -DPYTHON_DEFAULT_EXECUTABLE="${SYS_PYTHON}"                             \
    "${PYTHON_CMAKE_ARGS[@]}"                                               \
    -DINSTALL_PYTHON_EXAMPLES=ON                                            \
    -DENABLE_PYLINT=1                                                       \
    -DENABLE_FLAKE8=1                                                       \
    -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib-${PKG_VERSION}/modules"  \
    "${CMAKE_EXTRA_ARGS[@]}"                                                \
    "${CMAKE_DEBUG_ARGS[@]}"

  if [[ ! $? ]]; then
    echo "configure failed with $?"
    exit 1
  fi

fi

exit 1

make -j${CPU_COUNT} ${VERBOSE_CM}
