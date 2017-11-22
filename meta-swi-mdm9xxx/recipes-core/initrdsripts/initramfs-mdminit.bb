SUMMARY = "Mdm9xxx initramfs init scripts"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
DEPENDS = "virtual/kernel"

# init.sh need to source run.env, so need run.env.in and prepro.awk
FILESEXTRAPATHS_append := ":${THISDIR}/../initscripts/files"

SRC_URI = "file://init.sh \
           file://run.env.in \
           file://prepro.awk \
          "

PR = "r11"

do_install() {
    MACH=${MACHINE}

    chmod a+x ${WORKDIR}/prepro.awk

    for file in ${WORKDIR}/*.in ; do
        DMACH=${MACH#swi-}
        ${WORKDIR}/prepro.awk -v CPPFLAGS=-D${DMACH//-/_}=1 $file > ${file%.in}
    done

    install -d ${D}/etc
    install -m 0755 ${WORKDIR}/init.sh ${D}/init
    install -m 0755 ${WORKDIR}/run.env ${D}/etc/run.env
}

FILES_${PN} += " /init "

# Due to kernel depdendency
PACKAGE_ARCH = "${MACHINE_ARCH}"

