DESCRIPTION = "Stubbed 'bsinfo' tool"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r0"

#FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://bsinfo.in"

do_compile() {
    local targetname="bsvirt-${VIRT_ARCH}"
    local targetid="F0"
    local targetrev="01"

    if [[ "${VIRT_ARCH}" == "arm" ]]; then
        targetid="F0"
    elif [[ "${VIRT_ARCH}" == "x86" ]]; then
        targetid="F1"
    elif [[ "${VIRT_ARCH}" == "x86_64" ]]; then
        targetid="F2"
    else
        echo "Unknown target '${VIRT_ARCH}'"
        exit 1
    fi

    cp ${WORKDIR}/bsinfo.in ${WORKDIR}/bsinfo
    sed -i "s/#NAME/${targetname^^}/g" ${WORKDIR}/bsinfo
    sed -i "s/#ID/$targetid/g" ${WORKDIR}/bsinfo
    sed -i "s/#REV/$targetrev/g" ${WORKDIR}/bsinfo
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/bsinfo ${D}${bindir}/bsinfo
}
