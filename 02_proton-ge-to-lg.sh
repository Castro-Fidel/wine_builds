#!/bin/bash

cd "$(dirname "`readlink -f "$0"`")"
export SCRIPTS_PATH="$(pwd)"

if [[ ! -d "${SCRIPTS_PATH}/proton-ge-custom/" ]] ; then
    echo "GIT CLONE PROTON-GE-CUSTOM"
    cd "${SCRIPTS_PATH}"
    git clone --recurse-submodules http://github.com/gloriouseggroll/proton-ge-custom || exit 0
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

echo "adding 01-De-steamify-proton-s-WINE_for_PortProton.patch"
cd "${SCRIPTS_PATH}/proton-ge-custom/wine/"
patch -Np1 < ../../01-De-steamify-proton-s-WINE_for_PortProton.patch
