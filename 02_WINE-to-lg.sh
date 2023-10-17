#!/bin/bash

cd "$(dirname "`readlink -f "$0"`")"
export SCRIPTS_PATH="$(pwd)"
# if [[ -d "${SCRIPTS_PATH}/wine-tkg/" ]] ; then
#     rm -fr "${SCRIPTS_PATH}/wine-tkg/"
# fi
# git clone https://github.com/Kron4ek/wine-tkg "${SCRIPTS_PATH}/wine-tkg/"

git clone --recurse-submodules https://github.com/GloriousEggroll/wine-ge-custom.git

echo "adding reverse 01-WINE_for_PortProton"
cd "${SCRIPTS_PATH}/wine-ge-custom/proton-wine/"

echo "WINE for PP"
patch -RNp1 < ../../patches/01-WINE_for_PortProton.patch
# patch -Np0 < ../../patches/proton-exp-8.0.patch
