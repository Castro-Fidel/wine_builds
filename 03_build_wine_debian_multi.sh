#!/usr/bin/env bash

########################################################################
## A script for Wine compilation.
########################################################################

if [[ "$(id -u)" == "0" ]] ; then
    echo "Do not run the script from the superuser!"
    exit 1
fi
for PROGS in "wget" "tar" "xz" "bc" "git" "autoconf" "bwrap" ; do # "pv"
	if ! command -v "${PROGS}" &>/dev/null ; then
		PROGS_INST="${PROGS_INST} ${PROGS}" && vexit=1
	fi
done
if [[ "$vexit" == "1" ]] ; then
    echo "You will need to install: ${PROGS_INST}, and restart the script"
    exit 1
fi

export scriptdir="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

export WINE_FULL_NAME="PROTON_LG_8-20"
export WINE_GECKO="2.47.3"
export WINE_MONO="8.0.1"
export CUSTOM_SRC_PATH="$scriptdir"/wine-ge-custom/proton-wine/
# export CUSTOM_SRC_PATH="$scriptdir"/wine-tkg/
export BUILD_DIR="$scriptdir"/build
export GSTR_RUNTIME_PATH="$scriptdir"/extra/
export BOOTSTRAP_PATH=/opt/chroots_bullseye/bullseye_x86_64_chroot
export WINE_BUILD_OPTIONS="--disable-tests --with-x --with-mingw --with-gstreamer --disable-winemenubuilder --disable-win16"
export USE_CCACHE="true"

if [ -z "${XDG_CACHE_HOME}" ]; then
	export XDG_CACHE_HOME="${HOME}"/.cache
fi
mkdir -p "${XDG_CACHE_HOME}"/ccache
mkdir -p "${HOME}"/.ccache

build_with_bwrap () {
	bwrap --ro-bind "${BOOTSTRAP_PATH}" / --dev /dev --ro-bind /sys /sys \
		--proc /proc --tmpfs /tmp --tmpfs /home --tmpfs /run --tmpfs /var \
		--tmpfs /mnt --tmpfs /media --bind "${BUILD_DIR}" "${BUILD_DIR}" \
		--bind-try "${XDG_CACHE_HOME}"/ccache "${XDG_CACHE_HOME}"/ccache \
		--bind-try "${HOME}"/.ccache "${HOME}"/.ccache \
		--setenv PATH "/bin:/sbin:/usr/bin:/usr/sbin" "$@"
}
BWRAP="build_with_bwrap"

rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}" || exit 1

echo "Preparing Wine for compilation"

if [ -n "${CUSTOM_SRC_PATH}" ]; then
	is_url="$(echo "${CUSTOM_SRC_PATH}" | head -c 6)"

	if [ "${is_url}" = "git://" ] || [ "${is_url}" = "https:" ]; then
		git clone "${CUSTOM_SRC_PATH}" "${BUILD_DIR}"
	else
		if [ ! -d "${CUSTOM_SRC_PATH}" ]; then
			echo "CUSTOM_SRC_PATH is set to an incorrect or non-existent directory!"
			echo "Please make sure to use a directory with the correct Wine source code."
			exit 1
		fi

		cp -r "${CUSTOM_SRC_PATH}"/* "${BUILD_DIR}"
	fi

	WINE_VERSION="$(cat "${BUILD_DIR}"/VERSION | tail -c +14)"
	BUILD_NAME="${WINE_VERSION}"-custom
fi

if [ ! -d "${BUILD_DIR}" ]; then
	echo "No Wine source code found!"
	echo "Make sure that the correct Wine version is specified."
	exit 1
fi

if [ ! -d "${BOOTSTRAP_PATH}" ] ; then
	echo "Bootstraps are required for compilation!"
	exit 1
fi

export NCPU=$(nproc)
export RESULT_DIR="$BUILD_DIR/$WINE_FULL_NAME"
mkdir -p "$RESULT_DIR"

start=$(date +%s)

cd "${BUILD_DIR}" || exit 1
dlls/winevulkan/make_vulkan
tools/make_requests
autoreconf -f

export CROSSCC_X32="i686-w64-mingw32-gcc"
export CROSSCXX_X32="i686-w64-mingw32-g++"
export CROSSCC_X64="x86_64-w64-mingw32-gcc"
export CROSSCXX_X64="x86_64-w64-mingw32-g++"

export CFLAGS_X32="-march=i686 -msse2 -mfpmath=sse -O2 -ftree-vectorize"
export CFLAGS_X64="-march=x86-64 -msse3 -mfpmath=sse -O2 -ftree-vectorize"
export LDFLAGS="-Wl,-O1,--sort-common,--as-needed"

export CROSSCFLAGS_X32="${CFLAGS_X32}"
export CROSSCFLAGS_X64="${CFLAGS_X64}"
export CROSSLDFLAGS="${LDFLAGS}"

if [ "$USE_CCACHE" = "true" ]; then
	export CROSSCC_X32="ccache ${CROSSCC_X32}"
	export CROSSCXX_X32="ccache ${CROSSCXX_X32}"
	export CROSSCC_X64="ccache ${CROSSCC_X64}"
	export CROSSCXX_X64="ccache ${CROSSCXX_X64}"

	if [ -z "${XDG_CACHE_HOME}" ]; then
		export XDG_CACHE_HOME="${HOME}"/.cache
	fi

	mkdir -p "${XDG_CACHE_HOME}"/ccache
	mkdir -p "${HOME}"/.ccache
fi

export CROSSCC="${CROSSCC_X64}"
export CROSSCXX="${CROSSCXX_X64}"
export CFLAGS="${CFLAGS_X64}"
export CXXFLAGS="${CFLAGS_X64}"
export CROSSCFLAGS="${CROSSCFLAGS_X64}"
export CROSSCXXFLAGS="${CROSSCFLAGS_X64}"

echo "Configuring 64 bit build"
mkdir -p build64 && cd build64 || exit 1
${BWRAP} env CUPS_CFLAGS="-I/usr/include" \
PKG_CONFIG_PATH=/usr/share/pkgconfig \
LDFLAGS="-L${GSTR_RUNTIME_PATH}/lib64 -Wl,-O1,--sort-common,--as-needed,-rpath-link,${GSTR_RUNTIME_PATH}/lib64" \
../configure -C \
--enable-win64 \
--prefix="$RESULT_DIR" \
--libdir="$RESULT_DIR"/lib64 \
--bindir="$RESULT_DIR"/bin \
--datadir="$RESULT_DIR"/share \
--mandir="$RESULT_DIR"/share/man \
${WINE_BUILD_OPTIONS} || exit 1
sleep 5
${BWRAP} env \
LD_LIBRARY_PATH="${GSTR_RUNTIME_PATH}/lib64" \
CC="ccache gcc-10" CXX="ccache g++-10" \
make -j${NCPU} || exit 1
cd ..

export CROSSCC="${CROSSCC_X32}"
export CROSSCXX="${CROSSCXX_X32}"
export CFLAGS="${CFLAGS_X64}"
export CXXFLAGS="${CFLAGS_X64}"
export CROSSCFLAGS="${CROSSCFLAGS_X64}"
export CROSSCXXFLAGS="${CROSSCFLAGS_X64}"

echo "Configuring 32 bit build"
mkdir -p build32 && cd build32 || exit 1
${BWRAP} env GSTREAMER_CFLAGS="-I/usr/include/gstreamer-1.0 -I/usr/include/glib-2.0 -I/usr/lib/i386-linux-gnu/glib-2.0/include -I/usr/include/i386-linux-gnu -I/usr/lib/i386-linux-gnu/gstreamer-1.0/include -I/usr/include/orc-0.4 -I/usr/include/gudev-1.0 -I/usr/include/libdrm -pthread" \
GCRYPT_LIBS="-lgcrypt" \
GCRYPT_CFLAGS="-I/usr/include/gcrypt.h" \
CUPS_CFLAGS="-I/usr/include" \
PKG_CONFIG_PATH=/usr/share/pkgconfig \
LDFLAGS="-L${GSTR_RUNTIME_PATH}/lib32 -Wl,-O1,--sort-common,--as-needed,-rpath-link,$GSTR_RUNTIME_PATH/lib32" \
../configure -C \
--with-wine64=../build64 \
--prefix="$RESULT_DIR" \
--libdir="$RESULT_DIR"/lib \
--bindir="$RESULT_DIR"/bin \
--datadir="$RESULT_DIR"/share \
--mandir="$RESULT_DIR"/share/man \
${WINE_BUILD_OPTIONS} || exit 1
sleep 5
${BWRAP} env \
LD_LIBRARY_PATH="${GSTR_RUNTIME_PATH}/lib32" \
CC="ccache gcc-10" CXX="ccache g++-10" \
make -j${NCPU} || exit 1
cd ..

${BWRAP} env \
LD_LIBRARY_PATH=${GSTR_RUNTIME_PATH}/lib32 \
CC="ccache gcc-10" CXX="ccache g++-10" \
make -j${NCPU} -C build32 install-lib || exit 1


${BWRAP} env \
LD_LIBRARY_PATH=${GSTR_RUNTIME_PATH}/lib64 \
CC="ccache gcc-10" CXX="ccache g++-10" \
make -j${NCPU} -C build64 install-lib || exit 1

echo "Stripping build"
find "$RESULT_DIR"/bin -type f -exec strip {} \;
for _f in "$RESULT_DIR"/{bin,lib,lib64}/{wine/*,*}; do
	if [[ "$_f" = *.so ]] || [[ "$_f" = *.dll ]]; then
		strip --strip-unneeded "$_f" || true
	fi
done
for _f in "$RESULT_DIR"/{bin,lib,lib64}/{wine/{x86_64-unix,x86_64-windows,i386-unix,i386-windows}/*,*}; do
	if [[ "$_f" = *.so ]] || [[ "$_f" = *.dll ]]; then
		strip --strip-unneeded "$_f" || true
	fi
done

echo "$WINE_FULL_NAME" > "$RESULT_DIR"/version

echo "Copying 64 bit runtime libraries to build"
#copy sdl2, faudio, vkd3d, and ffmpeg libraries
cp -R "${GSTR_RUNTIME_PATH}"/lib64/* "$RESULT_DIR"/lib64/

echo "Copying 32 bit runtime libraries to build"
#copy sdl2, faudio, vkd3d, and ffmpeg libraries
cp -R "${GSTR_RUNTIME_PATH}"/lib32/* "$RESULT_DIR"/lib/

echo "Cleaning include files from build"
rm -rf "$RESULT_DIR"/include

echo "Add wine gecko + mono to the build"
mkdir -p "$RESULT_DIR"/share/wine/{gecko,mono}

wget https://dl.winehq.org/wine/wine-gecko/$WINE_GECKO/wine-gecko-$WINE_GECKO-x86_64.tar.xz -P "$RESULT_DIR"/share/wine/gecko/
tar -xf "$RESULT_DIR"/share/wine/gecko/wine-gecko-$WINE_GECKO-x86_64.tar.xz -C "$RESULT_DIR"/share/wine/gecko/
rm "$RESULT_DIR"/share/wine/gecko/wine-gecko-$WINE_GECKO-x86_64.tar.xz

wget https://dl.winehq.org/wine/wine-gecko/$WINE_GECKO/wine-gecko-$WINE_GECKO-x86.tar.xz -P "$RESULT_DIR"/share/wine/gecko/
tar -xf "$RESULT_DIR"/share/wine/gecko/wine-gecko-$WINE_GECKO-x86.tar.xz -C "$RESULT_DIR"/share/wine/gecko/
rm "$RESULT_DIR"/share/wine/gecko/wine-gecko-$WINE_GECKO-x86.tar.xz

wget https://github.com/madewokherd/wine-mono/releases/download/wine-mono-$WINE_MONO/wine-mono-$WINE_MONO-x86.tar.xz -P "$RESULT_DIR"/share/wine/mono/

tar -xf "$RESULT_DIR"/share/wine/mono/wine-mono-$WINE_MONO-x86.tar.xz -C "$RESULT_DIR"/share/wine/mono/
rm "$RESULT_DIR"/share/wine/mono/wine-mono-$WINE_MONO-x86.tar.xz

echo -e "\nCompilation complete\n\nCreating and compressing archives..."
tar -c -I 'xz -9 -T0' -f "${scriptdir}/$WINE_FULL_NAME.tar.xz" "$WINE_FULL_NAME"

end=$(date +%s)
seconds=$(echo "$end - $start" | bc)
echo -e "\nCompleted in $seconds seconds.\nThe builds should be in $RESULT_DIR\n"