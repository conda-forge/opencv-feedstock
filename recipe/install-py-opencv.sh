#!/bin/bash

set -ex

if [[ ! $(uname) =~ M* ]]; then
  function cygpath()
  {
    echo "$1"
  }
fi

echo "wtf 1 install-py-opencv.sh (top) PATH=$PATH"
source $(dirname $(cygpath -u "${CONDA_EXE}"))/activate $(cygpath -u "${PREFIX}")
echo "wtf 2 install-py-opencv.sh (h_env) PATH=$PATH"
unset CONDA_PATH_BACKUP
export CONDA_MAX_SHLVL=2
source $(dirname $(cygpath -u "${CONDA_EXE}"))/activate $(cygpath -u "${BUILD_PREFIX}")
echo "wtf 3 install-py-opencv.sh (_build_env) PATH=$PATH"

SRC_DIR_U=${SRC_DIR//\\//}

if [[ ${PY3K} == 1 ]]; then
    REAL_SP_DIR=${SP_DIR}
    conda activate ${SRC_DIR_U}/py3
    echo "wtf 4 install-py-opencv.sh (py3) PATH=$PATH"
    if [[ ${target_platform} =~ win* ]]; then
      export CONDA_SUBDIR=win-${ARCH}
    fi
    conda install -y python=${PY_VER} numpy=1.11 --override-channels -c local -c https://repo.continuum.io/pkgs/main
    pushd build/modules/python3
      LC_ALL=C find ./ -type f -exec sed -i'' -e "s/python3.7/python${PY_VER}/g" {} \;
      LC_ALL=C find ./ -type f -exec sed -i'' -e "s/37m/${PY_VER//./}m/g" {} \;
      # cp -rf ../../../../work /tmp/py35-work-post-sed
      echo $PATH
      echo which cmake
      if [[ ${target_platform} =~ win* ]]; then
        cmake --clean
        cmake --build . --target INSTALL --config Release
      else
        make clean
        make -j${CPU_COUNT} ${VERBOSE_CM}
        make install ${VERBOSE_CM}
      fi
      cp -rf ${SRC_DIR_U}/py3/lib/python${PY_VER}/site-packages/cv2* ${REAL_SP_DIR}
      # In-case there are other non-3.7 python 3 versions to be built for:
      find ./ -type f -exec sed -i'' -e "s/python${PY_VER}/python3.7/g" {} \;
      find ./ -type f -exec sed -i'' -e "s/${PY_VER//./}m/37m/g" {} \;
    popd
else
  pushd build/modules/python2
    if [[ ${target_platform} =~ win* ]]; then
      cmake --build . --target INSTALL --config Release
    else
      make -j${CPU_COUNT} ${VERBOSE_CM}
      make install ${VERBOSE_CM}
    fi
  popd
  cp -rf ${SRC_DIR_U}/py2/lib/python2.7/site-packages/cv* ${SP_DIR}
  # No idea, saw this once on a 2nd variant build (hdf5) after working for the 1st one, clearly this is a poor fix
  if [[ -f ${PREFIX}/python3.6/site-packages/cv2.cpython-py36m-powerpc64le-linux-gnu.so ]]; then
    mv ${PREFIX}/python3.6/site-packages/cv2.cpython-py36m-powerpc64le-linux-gnu.so ${PREFIX}/python3.6/site-packages/cv2.cpython-36m-powerpc64le-linux-gnu.so
  fi
fi
