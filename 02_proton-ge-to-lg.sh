#!/bin/bash

cd "$(dirname "`readlink -f "$0"`")"
export SCRIPTS_PATH="$(pwd)"

if [[ ! -d "${SCRIPTS_PATH}/proton-ge-custom/" ]] ; then
    echo "GIT CLONE PROTON-GE-CUSTOM"
    cd "${SCRIPTS_PATH}"
    git clone --recurse-submodules http://github.com/gloriouseggroll/proton-ge-custom || exit 1
else
    echo "GIT UPDATE PROTON-GE-CUSTOM"
    cd "${SCRIPTS_PATH}/proton-ge-custom/"
    git reset --hard origin/master
    git checkout
    git submodule update --init
fi

echo "adding protonprep-valve-staging.sh"
cd "${SCRIPTS_PATH}/proton-ge-custom/"
sh ./patches/protonprep-valve-staging.sh

if [[ ! -d "${SCRIPTS_PATH}/proton-ge-custom/wine.bak/" ]] ; then
    cp -fr "${SCRIPTS_PATH}/proton-ge-custom/wine" "${SCRIPTS_PATH}/proton-ge-custom/wine.bak"
fi
cd "${SCRIPTS_PATH}/proton-ge-custom/wine/"
echo "adding 01-De-steamify-proton-s-WINE_for_PortProton.patch"

patch -Np1 < ../../patches/01-De-steamify-proton-s-WINE_for_PortProton.patch || exit 1
# patch -Np1 < ../../patches/proton-exp-8.0.patch || exit 1

# sed -i "/CUSTOM_SRC_PATH=/c\export CUSTOM_SRC_PATH=${SCRIPTS_PATH}\/proton-ge-custom\/wine\/" "${SCRIPTS_PATH}/03_build_wine.sh"
