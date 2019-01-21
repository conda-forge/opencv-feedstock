#!/bin/bash
set -ex

pushd build
  make install ${VERBOSE_CM}
  rm -rf ${PREFIX}/lib/python*
popd
