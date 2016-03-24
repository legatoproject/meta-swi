DESCRIPTION = "Stubbed 'bsinfo' tool"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/\
${LICENSE};md5=0835ade698e0bcf8506ecda2f7b4f302"
PR = "r0"

SRC_URI = "file://bsinfo.in"

TARGET_NAME ?= "BSWPXXXX"

do_compile() {
    local targetname="${TARGET_NAME}"
    local targetid="F0"
    local targetrev="01"

    cp ${WORKDIR}/bsinfo.in ${WORKDIR}/bsinfo
    sed -i "s/#NAME/${targetname^^}/g" ${WORKDIR}/bsinfo
    sed -i "s/#ID/$targetid/g" ${WORKDIR}/bsinfo
    sed -i "s/#REV/$targetrev/g" ${WORKDIR}/bsinfo
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/bsinfo ${D}${bindir}/bsinfo
}

