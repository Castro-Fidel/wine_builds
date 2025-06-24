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
then tar -xf GE-Proton$GE_VERSION.tar.gz
else exit 1
fi

tar -xf GE-Proton$GE_VERSION.tar.gz

mv GE-Proton$GE_VERSION/files $PROTON_LG/
mv GE-Proton$GE_VERSION/PATENTS.AV1 $PROTON_LG/
mv GE-Proton$GE_VERSION/LICENSE* $PROTON_LG/

rm -r GE-Proton$GE_VERSION

rm $PROTON_LG/share/libtashkeel_model.ort
rm -r $PROTON_LG/share/{default_pfx,espeak-ng-data}
rm -r $PROTON_LG/lib/*w64-mingw32
rm -r $PROTON_LG/lib/{pkgconfig,cmake}
rm -r $PROTON_LG/lib/*/{cmake,fst,glslang,graphene-1.0,pkgconfig}
rm -f $PROTON_LG/lib/*/*steam*
rm -f  $PROTON_LG/lib/wine/*/*steam*
rm -f $PROTON_LG/lib/wine/*/*-windows/winemenubuilder.exe

chmod -R 755 "$PROTON_LG"/
find "$PROTON_LG"/ -type f -exec strip --strip-unneeded {} +

echo -e "\nCreating and compressing VKD3D archive..."
VKD3D_VER="$(cat $PROTON_LG/lib/wine/vkd3d-proton/version | awk -F'-' '{print $3 "-" $4}')"
mkdir -p vkd3d-proton-$VKD3D_VER/{x64,x86}
# x86
cp $PROTON_LG/lib/wine/vkd3d-proton/version vkd3d-proton-$VKD3D_VER/x86/
mv $PROTON_LG/lib/vkd3d/i386-windows/* vkd3d-proton-$VKD3D_VER/x86/
mv $PROTON_LG/lib/wine/vkd3d-proton/i386-windows/* vkd3d-proton-$VKD3D_VER/x86/
# x64
cp $PROTON_LG/lib/wine/vkd3d-proton/version vkd3d-proton-$VKD3D_VER/x64/
mv $PROTON_LG/lib/vkd3d/x86_64-windows/* vkd3d-proton-$VKD3D_VER/x64/
mv $PROTON_LG/lib/wine/vkd3d-proton/x86_64-windows/* vkd3d-proton-$VKD3D_VER/x64/

rm -r $PROTON_LG/lib/vkd3d/
rm -r $PROTON_LG/lib/wine/vkd3d-proton/
tar -c -I 'xz -9 -T0' -f "${scriptdir}/vkd3d-proton-$VKD3D_VER.tar.xz" "vkd3d-proton-$VKD3D_VER"
rm -r vkd3d-proton-$VKD3D_VER

echo -e "\nCreating and compressing DXVK archive..."
DXVK_VER="$(cat $PROTON_LG/lib/wine/dxvk/version | awk -F'\\(v' '{print $2}' | awk -F'-' '{print $1 "-" $2}')"
mkdir -p dxvk-$DXVK_VER/{x64,x32}
# x32
cp $PROTON_LG/lib/wine/nvapi/version dxvk-$DXVK_VER/x32/nvapi-version
mv $PROTON_LG/lib/wine/nvapi/i386-windows/* dxvk-$DXVK_VER/x32/
cp $PROTON_LG/lib/wine/dxvk/version dxvk-$DXVK_VER/x32/version
mv $PROTON_LG/lib/wine/dxvk/i386-windows/* dxvk-$DXVK_VER/x32/
# x64
cp $PROTON_LG/lib/wine/nvapi/version dxvk-$DXVK_VER/x64/nvapi-version
mv $PROTON_LG/lib/wine/nvapi/x86_64-windows/* dxvk-$DXVK_VER/x64/
cp $PROTON_LG/lib/wine/dxvk/version dxvk-$DXVK_VER/x64/
mv $PROTON_LG/lib/wine/dxvk/x86_64-windows/* dxvk-$DXVK_VER/x64/

rm -r $PROTON_LG/lib/wine/nvapi/
rm -r $PROTON_LG/lib/wine/dxvk
tar -c -I 'xz -9 -T0' -f "${scriptdir}/dxvk-$DXVK_VER.tar.xz" "dxvk-$DXVK_VER"
rm -r dxvk-$DXVK_VER

echo -e "\nCreating and compressing archives..."
tar -c -I 'xz -9 -T0' -f "${scriptdir}/$PROTON_LG.tar.xz" "$PROTON_LG"
rm -r $PROTON_LG

echo "Done."
