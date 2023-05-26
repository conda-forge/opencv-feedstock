#!/bin/bash

DEBUG_CMAKE_BUILD_SYSTEM=yes
declare -a CMAKE_DEBUG_ARGS PYTHON_CMAKE_ARGS VAR_DEPS DEPS_DEFAULTS CMAKE_EXTRA_ARGS

# C11 should be what is supported by default
export CXXFLAGS="$CXXFLAGS -D__STDC_CONSTANT_MACROS"
export CPPFLAGS="${CPPFLAGS//-std=c++17/-std=c++11}"
export CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

if [[ ${DEBUG_CMAKE_BUILD_SYSTEM} == yes ]]; then
#  CMAKE_DEBUG_ARGS+=("--debug-trycompile")
#  CMAKE_DEBUG_ARGS+=("-Wdev")
#  CMAKE_DEBUG_ARGS+=("--debug-output")
#  CMAKE_DEBUG_ARGS+=("--trace")
  CMAKE_DEBUG_ARGS+=("-DOPENCV_CMAKE_DEBUG_MESSAGES=1")
fi

echo "PYTHON_CMAKE_ARGS="
echo "${PYTHON_CMAKE_ARGS[@]}"

# Set defaults for dependencies that change across OSes
# This should match the meta.yaml deps section
if [[ "$build_variant" == "normal" ]]; then
  echo "Building normal variant"
  VAR_DEPS=(EIGEN FFMPEG PROTOBUF GSTREAMER OPENJPEG OPENMP QT WEBP)
  DEPS_DEFAULTS=(1 0 0 1 1 1 5 0)
else
  echo "Building headless variant"
  VAR_DEPS=(EIGEN FFMPEG PROTOBUF GSTREAMER OPENJPEG OPENMP WEBP)
  DEPS_DEFAULTS=(1 0 0 1 1 1 0)
fi
if [[ ${#DEPS_DEFAULTS[@]} != ${#VAR_DEPS[@]} ]];then echo Setting defaults failed: Length mismatch;exit 1; fi
for ii in ${!VAR_DEPS[@]};do
    eval "WITH_${VAR_DEPS[ii]}=${DEPS_DEFAULTS[ii]}"
done

# Assemble CMAKE_EXTRA_ARGS  with OS-specific settings
echo "Platform: ${target_platform}"
if [[ ${target_platform} == osx-* ]]; then
  CMAKE_EXTRA_ARGS+=("-DCMAKE_OSX_SYSROOT=${CONDA_BUILD_SYSROOT}")
  CMAKE_EXTRA_ARGS+=("-DZLIB_LIBRARY_RELEASE=${PREFIX}/lib/libz.dylib")
  WITH_OPENMP=0
  if [[ ${target_platform} == osx-arm64 ]]; then
    WITH_OPENJPEG=0
  fi
elif [[ ${target_platform} == linux-64 ]];then
  # for qt the value is coerced to boolean but it also used to set the version
  # of the QT cmake config file looked for
  WITH_PROTOBUF=1
  WITH_WEBP=1
  WITH_FFMPEG=1
elif [[ ${target_platform} == linux-ppc64le ]];then
    # TODO: this should likely be somewhere else... perhaps the compiler activation
  CMAKE_ARGS=" -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH=$PREFIX;$BUILD_PREFIX/x86_64-conda-linux-gnu/sysroot -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_INSTALL_LIBDIR=lib"
  WITH_QT=0
  WITH_GSTREAMER=0
elif [[ ${target_platform} == linux-aarch64 ]];then
    echo aarch64
else
    echo Unsupported platform
fi

# append dependencies to CMAKE_EXTRA_ARGS
for dep in "${VAR_DEPS[@]}";do
    varname=WITH_${dep}
    CMAKE_EXTRA_ARGS+=("-D${varname}=${!varname}")
done
# append debug args
CMAKE_EXTRA_ARGS+=("${CMAKE_DEBUG_ARGS[@]}")
echo "CMake_EXTRA_ARGS : ${CMAKE_EXTRA_ARGS[@]}"

export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$PREFIX/lib/pkgconfig
export PKG_CONFIG_LIBDIR=$PREFIX/lib

mkdir -p build
cd build
cmake .. -LAH -GNinja                                                     \
  ${CMAKE_ARGS}                                                           \
  "${CMAKE_EXTRA_ARGS[@]}" `#includes platform specific deps and options` \
  "${PYTHON_CMAKE_ARGS[@]}"                                               \
  -DOPENCV_GENERATE_PKGCONFIG=ON                                          \
  -DBUILD_DOCS=0                                                          \
  -DBUILD_JASPER=0                                                        \
  -DBUILD_JPEG=0                                                          \
  -DBUILD_OPENJPEG=0                                                      \
  -DBUILD_LIBPROTOBUF_FROM_SOURCES=0                                      \
  -DBUILD_OPENEXR=ON                                                      \
  -DBUILD_PERF_TESTS=0                                                    \
  -DBUILD_PNG=0                                                           \
  -DBUILD_PROTOBUF=0                                                      \
  -DBUILD_TESTS=0                                                         \
  -DBUILD_TIFF=0                                                          \
  -DBUILD_ZLIB=0                                                          \
  -DBUILD_WEBP=0                                                          \
  -DBUILD_opencv_apps=OFF `# issue linking with opencv_model_diagnostics` \
  -DCMAKE_BUILD_TYPE="Release"                                            \
  -DCMAKE_CROSSCOMPILING=ON         `# may not need`                      \
  -DENABLE_CONFIG_VERIFICATION=ON                                         \
  -DENABLE_FLAKE8=0                                                       \
  -DENABLE_PYLINT=0      `# used for docs and examples`                   \
  -DINSTALL_C_EXAMPLES=OFF                                                \
  -DINSTALL_PYTHON_EXAMPLES=ON                                            \
  -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib-${PKG_VERSION}/modules"  \
  -DOpenCV_INSTALL_BINARIES_PREFIX=""                                     \
  -DPROTOBUF_UPDATE_FILES=ON  `# should be used if using protobuf`        \
  -DPYTHON_DEFAULT_EXECUTABLE=${PREFIX}/bin/python                        \
  -DWITH_1394=OFF                                                         \
  -DWITH_CUDA=OFF                                                         \
  -DWITH_GTK=OFF                                                          \
  -DWITH_ITT=OFF                                                          \
  -DWITH_JASPER=OFF                                                       \
  -DWITH_LAPACK=OFF                                                       \
  -DWITH_MATLAB=OFF                                                       \
  -DWITH_OPENCL=OFF                                                       \
  -DWITH_OPENCLAMDBLAS=OFF                                                \
  -DWITH_OPENCLAMDFFT=OFF                                                 \
  -DWITH_OPENNI=OFF                                                       \
  -DWITH_TESSERACT=OFF                                                    \
  -DWITH_VA=OFF                                                           \
  -DWITH_VA_INTEL=OFF                                                     \
  -DWITH_VTK=OFF                                                          \
  -DBUILD_opencv_python2=OFF


if [[ ! $? ]]; then
  echo "configure failed with $?"
  exit 1
fi

cmake --build .

