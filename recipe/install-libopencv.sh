#!/bin/bash

pushd build
  make install ${VERBOSE_CM}
  rm -rf ${PREFIX}/lib/python{2.7,3.6}
popd
