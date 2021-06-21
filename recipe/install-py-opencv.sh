#!/bin/bash

# We likely do not need to run cmake so everything but the 'cp' can be removed.
pushd build/modules/python${PY_VER}
  cmake --build . --target INSTALL --config Release
  cp -rf ${SRC_DIR}/py${PY_VER}/lib/python${PY_VER}/site-packages/cv* ${SP_DIR}
popd
