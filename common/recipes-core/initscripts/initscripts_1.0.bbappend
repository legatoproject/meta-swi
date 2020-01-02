# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI_append = " file://prepro.awk \
                   file://run.env.in \
                   file://run_getty.sh.in \
                   file://mountall.sh \
                   file://mount_unionfs.in \
                   file://etc/group \
                   file://etc/gshadow \
                   file://etc/passwd \
                   file://etc/shadow \
                   file://rcS-default \
                   file://rcS \
                   file://rcK \
                   file://ecm.conf.in \
                   file://dnsmasq.ecm.conf.in \
                 "

TMPL_FLAGS ??= ""

ECM_INTERFACE ??="ecm0"
ECM_TARGET_IP ?= "192.168.2.2"
ECM_HOST_IP ?= "192.168.2.3"
ECM_DHCP_RANGE_HIGH ?= "192.168.2.3"
ECM_MASK ?= "255.255.255.0"

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

    sed -i 's/#ECM_TARGET_IP#/${ECM_TARGET_IP}/g' ${WORKDIR}/ecm.conf.in
    sed -i 's/#ECM_HOST_IP#/${ECM_HOST_IP}/g' ${WORKDIR}/ecm.conf.in
    sed -i 's/#ECM_INTERFACE#/${ECM_INTERFACE}/g' ${WORKDIR}/dnsmasq.ecm.conf.in
    sed -i 's/#ECM_DHCP_RANGE_LOW#/${ECM_HOST_IP}/g' ${WORKDIR}/dnsmasq.ecm.conf.in
    sed -i 's/#ECM_DHCP_RANGE_HIGH#/${ECM_DHCP_RANGE_HIGH}/g' ${WORKDIR}/dnsmasq.ecm.conf.in
    sed -i 's/#ECM_MASK#/${ECM_MASK}/g' ${WORKDIR}/ecm.conf.in

    for file in ${WORKDIR}/*.in ; do
        ${WORKDIR}/prepro.awk -v CPPFLAGS="${TMPL_FLAGS} -D${mach_flag}" $file > ${file%.in}
    done

}

do_install_append () {

    process_templates

    # Environment file that should be sourced by other scripts

    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env
    install -m 0644 ${WORKDIR}/ecm.conf -D ${D}${sysconfdir}/legato/ecm.conf
    install -m 0644 ${WORKDIR}/dnsmasq.ecm.conf -D ${D}${sysconfdir}/dnsmasq.d/dnsmasq.ecm.conf

    install -m 0755 ${WORKDIR}/run_getty.sh -D ${D}${sbindir}/run_getty.sh

    install -m 0755 ${WORKDIR}/mountall.sh   ${D}${sysconfdir}/init.d

    # Script that mounts unionfs
    install -m 0755 -d ${D}${DATA_DIR}
    install -D -m 0755 ${WORKDIR}/mount_unionfs -D ${D}${sysconfdir}/init.d/mount_unionfs

    update-rc.d -r ${D} -f mount_unionfs remove
    update-rc.d -r ${D} mount_unionfs start 07 S . stop 96 S .

    install -D -m 0444 ${WORKDIR}/etc/group -D ${D}${sysconfdir}/group
    install -D -m 0400 ${WORKDIR}/etc/gshadow -D ${D}${sysconfdir}/gshadow
    install -D -m 0444 ${WORKDIR}/etc/passwd -D ${D}${sysconfdir}/passwd
    install -D -m 0400 ${WORKDIR}/etc/shadow -D ${D}${sysconfdir}/shadow

    install -d ${D}${sysconfdir}/default
    install -m 0444 ${WORKDIR}/rcS-default -D ${D}${sysconfdir}/default/rcS
    install -m 0755 ${WORKDIR}/rcS           ${D}${sysconfdir}/init.d
    install -m 0755 ${WORKDIR}/rcK           ${D}${sysconfdir}/init.d

    # Provide an empty resolv.conf for DNS utility to manipulate later
    touch ${D}${sysconfdir}/resolv.conf
}

