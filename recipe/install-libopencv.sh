#!/bin/bash

pushd build
  make install ${VERBOSE_CM}
  rm -rf ${PREFIX}/lib/python*
popd
