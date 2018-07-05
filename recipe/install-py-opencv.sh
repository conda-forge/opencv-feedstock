#!/bin/bash

if [[ ${PY3K} == 1 ]]; then
  if [[ ${PY_VER} == 3.7 ]]; then
    cp -rf ${SRC_DIR}/py3/lib/python${PY_VER}/site-packages/cv2* ${SP_DIR}
    cp -rf ${SRC_DIR}/cv2* ${SP_DIR}
  else
    cp -rf ${SRC_DIR}/py3/lib/python3.7/site-packages/cv2* ${SRC_DIR}
    conda activate ${SRC_DIR}/py3
    REAL_SP_DIR=${SP_DIR}
    conda install -y python=${PY_VER} numpy=1.11 --override-channels -c local -c https://repo.continuum.io/pkgs/main
    pushd build/modules/python3
      make clean
      find ./ -type f -exec sed -i'' -e "s/python3.7/python${PY_VER}/g" {} \;
      find ./ -type f -exec sed -i'' -e "s/37m/${PY_VER//./}m/g" {} \;
      # cp -rf ../../../../work /tmp/py35-work-post-sed
      make -j${CPU_COUNT} ${VERBOSE_CM}
      make install ${VERBOSE_CM}
      cp -rf ${SRC_DIR}/py3/lib/python${PY_VER}/site-packages/cv2* ${REAL_SP_DIR}
      # In-case there are other non-3.7 python 3 versions to be built for:
      find ./ -type f -exec sed -i'' -e "s/python${PY_VER}/python3.7/g" {} \;
      find ./ -type f -exec sed -i'' -e "s/${PY_VER//./}m/py37m/g" {} \;
    popd
  fi
else
  pushd build/modules/python2
    make install ${VERBOSE_CM}
  popd
  cp -rf ${SRC_DIR}/py2/lib/python2.7/site-packages/cv* ${SP_DIR}
  # No idea, saw this once on a 2nd variant build (hdf5) after working for the 1st one, clearly this is a poor fix
  if [[ -f ${PREFIX}/python3.6/site-packages/cv2.cpython-py36m-powerpc64le-linux-gnu.so ]]; then
    mv ${PREFIX}/python3.6/site-packages/cv2.cpython-py36m-powerpc64le-linux-gnu.so ${PREFIX}/python3.6/site-packages/cv2.cpython-36m-powerpc64le-linux-gnu.so
  fi
fi
