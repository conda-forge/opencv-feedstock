#!/usr/bin/env bash

set -x

echo "Removing homebrew from Circle CI to avoid conflicts."
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall > ~/uninstall_homebrew
chmod +x ~/uninstall_homebrew
~/uninstall_homebrew -fq
rm ~/uninstall_homebrew

echo "Installing a fresh version of Miniconda."
MINICONDA_URL="https://repo.continuum.io/miniconda"
MINICONDA_FILE="Miniconda3-latest-MacOSX-x86_64.sh"
curl -L -O "${MINICONDA_URL}/${MINICONDA_FILE}"
bash $MINICONDA_FILE -b

echo "Configuring conda."
source ~/miniconda3/bin/activate root

conda install -n root -c conda-forge --quiet --yes conda-forge-ci-setup=2 conda-build
mangle_compiler ./ ./recipe .ci_support/${CONFIG}.yaml
setup_conda_rc ./ ./recipe ./.ci_support/${CONFIG}.yaml


source run_conda_forge_build_setup



set -e

make_build_number ./ ./recipe ./.ci_support/${CONFIG}.yaml

conda build ./recipe -m ./.ci_support/${CONFIG}.yaml --clobber-file ./.ci_support/clobber_${CONFIG}.yaml

upload_package ./ ./recipe ./.ci_support/${CONFIG}.yaml