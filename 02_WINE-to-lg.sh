#!/bin/bash

cd "$(dirname "`readlink -f "$0"`")"
export SCRIPTS_PATH="$(pwd)"
# if [[ -d "${SCRIPTS_PATH}/wine-tkg/" ]] ; then
#     rm -fr "${SCRIPTS_PATH}/wine-tkg/"
# fi
# git clone https://github.com/Kron4ek/wine-tkg "${SCRIPTS_PATH}/wine-tkg/"

git clone --branch Proton8-25 --recurse-submodules https://github.com/GloriousEggroll/proton-wine.git
cd "${SCRIPTS_PATH}/proton-wine/"


echo "adding reverse 01-WINE_for_PortProton"

echo "WINE for PP"
patch -RNp1 < ../patches/01-WINE_for_PortProton.patch
# patch -Np0 < ../patches/proton-exp-8.0.patch
