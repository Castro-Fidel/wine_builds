#!/usr/bin/env bash

# запрещаем запуск от root
if [[ $(id -u) -eq 0 ]] ; then
    echo "Do not run the script from the superuser!"
    exit 1
fi

# проверяем необходимое установленное ПО в систему
for PROGS in "wget" "tar" "bc" ; do # "pv"
	if [[ ! -x "$(which "${PROGS}" 2>/dev/null)" ]] ; then
		PROGS_INST="${PROGS_INST} ${PROGS}" && vexit=1
	fi
done
if [[ "${vexit}" -eq "1" ]] ; then
    echo "You will need to install: ${PROGS_INST}, and restart the script"
    exit 1
fi

# запускаем таймер
start=$(date +%s)

# переход в каталог со скриптом
cd "$(dirname "`readlink -f "$0"`")"
export SCRIPTS_PATH="$(pwd)"

# загружаем ProtonGE_КАКАЯТО_ВЕРСИЯ в каталог со скриптом
if [[ -z "${PROTON_GE}" ]] ; then
    echo "Set variable PROTON_GE"
    exit 1
else
    PROTON_GE_VER="${PROTON_GE}"
fi

wget https://github.com/GloriousEggroll/proton-ge-custom/releases/download/GE-Proton${PROTON_GE_VER}/GE-Proton${PROTON_GE_VER}.tar.gz

# распаковываем ProtonGE_КАКАЯТО_ВЕРСИЯ в каталог со скриптом
tar -xzvf "${SCRIPTS_PATH}/GE-Proton${PROTON_GE_VER}.tar.gz"

# переносим необходимое
mv "${SCRIPTS_PATH}/GE-Proton${PROTON_GE_VER}/files" "${SCRIPTS_PATH}/PROTON_GE_${PROTON_GE_VER}"
mv "${SCRIPTS_PATH}/GE-Proton${PROTON_GE_VER}/PATENTS.AV1" "${SCRIPTS_PATH}/PROTON_GE_${PROTON_GE_VER}/"

# удаляем всё лишние
rm -fr "${SCRIPTS_PATH}/GE-Proton${PROTON_GE_VER}"
rm -f "${SCRIPTS_PATH}/GE-Proton${PROTON_GE_VER}.tar.gz"
rm -fr "${SCRIPTS_PATH}/PROTON_GE_${PROTON_GE_VER}/share/default_pfx/"

# добавляем всё необходимое для PortProton (версия WINE и т.п.)
echo "PROTON_GE_${PROTON_GE_VER}" > "${SCRIPTS_PATH}/PROTON_GE_${PROTON_GE_VER}/version"

# запаковываем ProtonGE_КАКАЯТО_ВЕРСИЯ и удалем каталог с ProtoGE
tar -c -I 'xz -9 -T0' -f "${SCRIPTS_PATH}/PROTON_GE_${PROTON_GE_VER}.tar.xz" "./PROTON_GE_${PROTON_GE_VER}"
rm -fr "${SCRIPTS_PATH}/PROTON_GE_${PROTON_GE_VER}"

# останавливаем таймер
end=$(date +%s)
seconds=$(echo "$end - $start" | bc)

# готово
echo "Completed in $seconds seconds."
