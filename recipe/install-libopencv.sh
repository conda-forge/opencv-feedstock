#!/bin/bash

pushd build
  make install ${VERBOSE_CM}
popd
