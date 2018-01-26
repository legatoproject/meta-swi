# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://prepro.awk \
                   file://run.env.in \
                   file://mount_unionfs.in \
                 "

TMPL_FLAGS ??= ""

# Required by mount_unionfs
DATA_DIR = "/data"
FILES_${PN} += " ${DATA_DIR}"

# Create a package that contains only run.env
PACKAGES_prepend += "${PN}-runenv "
FILES_${PN}-runenv = "${sysconfdir}/run.env"
RDEPENDS_${PN} += "${PN}-runenv"

#
# Preprocess *.in files with @if directives.
#
# Default flags can be extended through TMPL_FLAGS
#
process_templates() {
    set -x

    chmod a+x ${WORKDIR}/prepro.awk

    mach=${MACHINE}
    mach_flag=${mach#swi-}
    mach_flag=${mach_flag//-/_}

    for file in ${WORKDIR}/*.in ; do
        ${WORKDIR}/prepro.awk -v CPPFLAGS="${TMPL_FLAGS} -D${mach_flag}" $file > ${file%.in}
    done
}

do_install_append () {

    process_templates

    # Environment file that should be sourced by other scripts
    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env

    # Script that mounts unionfs
    install -m 0755 -d ${D}${DATA_DIR}
    install -D -m 0755 ${WORKDIR}/mount_unionfs -D ${D}${sysconfdir}/init.d/mount_unionfs

    update-rc.d -r ${D} -f mount_unionfs remove
    update-rc.d -r ${D} mount_unionfs start 07 S . stop 96 S .
}

