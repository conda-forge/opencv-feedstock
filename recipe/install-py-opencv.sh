#!/bin/bash

if [[ ${PY3K} == 1 ]]; then
  if [[ ${PY_VER} == 3.6 ]]; then
    cp -rf ${SRC_DIR}/py3/lib/python3.6/site-packages/cv2* ${SP_DIR}
  else
    conda activate ${SRC_DIR}/py3
    REAL_SP_DIR=${SP_DIR}
    conda install -y python=${PY_VER} --override-channels -c https://repo.continuum.io/pkgs/main
    pushd build/modules/python3
      make clean
      find ./ -type f -exec sed -i '' -e "s/python3.6/python${PY_VER}/g" {} \;
      find ./ -type f -exec sed -i '' -e "s/36m/${PY_VER//./}m/g" {} \;
      cp -rf ../../../../work /tmp/py35-work-post-sed
      make -j${CPU_COUNT} ${VERBOSE_CM}
      make install ${VERBOSE_CM}
      cp -rf ${SRC_DIR}/py3/lib/python${PY_VER}/site-packages/cv2* ${REAL_SP_DIR}
      # In-case there are other non-3.6 python 3 versions to be built for:
      find ./ -type f -exec sed -i '' -e "s/python${PY_VER}/python3.6/g" {} \;
      find ./ -type f -exec sed -i '' -e "s/${PY_VER//./}m/py36m/g" {} \;
    popd
  fi
else
  cp -rf ${SRC_DIR}/py2/lib/python2.7/site-packages/cv* ${SP_DIR}
fi
