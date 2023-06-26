#!/bin/bash
set -ex

cd build
cmake --install .

cd ..
rm -rf build
