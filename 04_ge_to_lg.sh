#!/usr/bin/env bash

if [[ "$(id -u)" == "0" ]] ; then
    echo "Do not run the script from the superuser!"
    exit 1
fi
for PROGS in "wget" "tar" "xz" ; do
	if ! command -v "${PROGS}" &>/dev/null ; then
		PROGS_INST="${PROGS_INST} ${PROGS}" && vexit=1
	fi
done
if [[ "$vexit" == "1" ]] ; then
    echo "You will need to install: ${PROGS_INST}, and restart the script"
    exit 1
fi

scriptdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
cd "$scriptdir"

if [[ ! -z "$1" ]]
then GE_VERSION="$1"
else echo "used: $0 version" && exit 1
fi
PROTON_LG=PROTON_LG_$GE_VERSION

if wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton$GE_VERSION/GE-Proton$GE_VERSION.tar.gz
then
	tar -xf GE-Proton$GE_VERSION.tar.gz
	rm GE-Proton$GE_VERSION.tar.gz
fi

mv GE-Proton$GE_VERSION/files $PROTON_LG/
mv GE-Proton$GE_VERSION/PATENTS.AV1 $PROTON_LG/
rm -r GE-Proton$GE_VERSION

echo "$PROTON_LG" > $PROTON_LG/version
rm -r $PROTON_LG/share/default_pfx
rm -r $PROTON_LG/*/{cmake,fst,glslang,graphene-1.0,pkgconfig}
rm -f $PROTON_LG/*/*steam*
rm -f $PROTON_LG/*/wine/*/*steam*
rm -f $PROTON_LG/*/wine/*-windows/winemenubuilder.exe

VKD3D_VER="$(cat $PROTON_LG/lib/wine/vkd3d-proton/version | awk -F'-' '{print $3 "-" $4}')"
mkdir -p vkd3d-proton-$VKD3D_VER/{x64,x86}
# x86
mv $PROTON_LG/lib/vkd3d/* vkd3d-proton-$VKD3D_VER/x86/
rm -r $PROTON_LG/lib/vkd3d/
mv $PROTON_LG/lib/wine/vkd3d-proton/* vkd3d-proton-$VKD3D_VER/x86/
rm -r $PROTON_LG/lib/wine/vkd3d-proton/
# x64
mv $PROTON_LG/lib64/vkd3d/* vkd3d-proton-$VKD3D_VER/x64/
rm -r $PROTON_LG/lib64/vkd3d/
mv $PROTON_LG/lib64/wine/vkd3d-proton/* vkd3d-proton-$VKD3D_VER/x64/
rm -r $PROTON_LG/lib64/wine/vkd3d-proton/
echo -e "\nCreating and compressing VKD3D archive..."
tar -c -I 'xz -9 -T0' -f "${scriptdir}/vkd3d-proton-$VKD3D_VER.tar.xz" "vkd3d-proton-$VKD3D_VER"
rm -fr vkd3d-proton-$VKD3D_VER

DXVK_VER="$(cat $PROTON_LG/lib/wine/dxvk/version | awk -F'\\(v' '{print $2}' | awk -F'-' '{print $1 "-" $2}')"
mkdir -p dxvk-$DXVK_VER/{x64,x32}
# x32
mv $PROTON_LG/lib/wine/nvapi/version dxvk-$DXVK_VER/x32/nvapi-version
mv $PROTON_LG/lib/wine/nvapi/* dxvk-$DXVK_VER/x32/
rm -r $PROTON_LG/lib/wine/nvapi/
mv $PROTON_LG/lib/wine/dxvk/* dxvk-$DXVK_VER/x32/
rm -r $PROTON_LG/lib/wine/dxvk/
# x64
mv $PROTON_LG/lib64/wine/nvapi/version dxvk-$DXVK_VER/x64/nvapi-version
mv $PROTON_LG/lib64/wine/nvapi/* dxvk-$DXVK_VER/x64/
rm -r $PROTON_LG/lib64/wine/nvapi/
mv $PROTON_LG/lib64/wine/dxvk/* dxvk-$DXVK_VER/x64/
rm -r $PROTON_LG/lib64/wine/dxvk/
echo -e "\nCreating and compressing DXVK archive..."
tar -c -I 'xz -9 -T0' -f "${scriptdir}/dxvk-$DXVK_VER.tar.xz" "dxvk-$DXVK_VER"
rm -fr dxvk-$DXVK_VER

rm -fr $PROTON_LG/*/wine/d8vk

echo -e "\nCreating and compressing archives..."
tar -c -I 'xz -9 -T0' -f "${scriptdir}/$PROTON_LG.tar.xz" "$PROTON_LG"
rm -fr $PROTON_LG

echo "Done."
