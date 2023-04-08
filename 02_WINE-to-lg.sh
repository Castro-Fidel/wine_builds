#!/bin/bash

cd "$(dirname "`readlink -f "$0"`")"
export SCRIPTS_PATH="$(pwd)"
if [[ -d "${SCRIPTS_PATH}/wine-tkg/" ]] ; then
    rm -f "${SCRIPTS_PATH}/wine-tkg/"
fi
git clone https://github.com/Kron4ek/wine-tkg "${SCRIPTS_PATH}/wine-tkg/"

echo "adding reverse 01-WINE_for_PortProton"
cd "${SCRIPTS_PATH}/wine-tkg/"
patch -RNp1 < ../01-WINE_for_PortProton.patch

# sed -i "/CUSTOM_SRC_PATH=/c\export CUSTOM_SRC_PATH=${SCRIPTS_PATH}/wine-tkg/" "${SCRIPTS_PATH}/03_build_wine.sh"
