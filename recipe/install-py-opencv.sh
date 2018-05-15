#!/bin/bash

if [[ ${PY3K} == 1 ]]; then
  if [[ ${PY_VER} == 3.6 ]]; then
    cp -rf ${SRC_DIR}/py3/lib/python3.6/site-packages/cv2* ${SP_DIR}
  else
    conda activate ${SRC_DIR}/py3
    conda install -y python=${PY_VER}
    pushd build/modules/python3
      make clean
      find ./ -type f -exec sed -i '' -e "s/python3.6/python${PY_VER}/g" {} \;
      make -j${CPU_COUNT} ${VERBOSE_CM}
      make install ${VERBOSE_CM}
      cp -rf ${SRC_DIR}/py3/lib/python${PY_VER}/site-packages/cv2* ${SP_DIR}
      # In-case there are other non-3.6 python 3 versions to be built for.
      find ./ -type f -exec sed -i '' -e "s/python${PY_VER}/python3.6/g" {} \;
    popd
  fi
else
  cp -rf ${SRC_DIR}/py2/lib/python2.7/site-packages/cv* ${SP_DIR}
fi
