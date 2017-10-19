# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://functions \
           file://devpts \
           file://mountall.sh \
           file://bootmisc.sh \
           file://checkfs.sh \
           file://single \
           file://urandom \
           file://volatiles \
           file://inittab \
           file://mdev.conf \
           file://usb.sh \
           file://find-touchscreen.sh \
           file://rcS \
           file://rcK \
           file://GPLv2.patch \
          "
SRC_URI_append_swi-mdm9x15 += "file://bringup_ecm.sh \
                               file://bridge_ecm.sh \
                              "

SRC_URI_append_arm = " file://alignment.sh"

KERNEL_VERSION = ""

inherit update-alternatives
DEPENDS_append = " update-rc.d-native"

ALTERNATIVE_PRIORITY = "90"
ALTERNATIVE_${PN} = "functions"
ALTERNATIVE_LINK_NAME[functions] = "${sysconfdir}/init.d/functions"

HALTARGS ?= "-d -f"

do_configure() {
}

do_install () {
#
# Create directories and install device independent scripts
#
    install -d ${D}${sysconfdir}/mdev
	install -d ${D}${sysconfdir}/init.d
	install -d ${D}${sysconfdir}/default
	install -d ${D}${sysconfdir}/default/volatiles
	# Holds state information pertaining to urandom
	install -d ${D}/var/lib/urandom

	install -m 0644    ${WORKDIR}/inittab	${D}${sysconfdir}/inittab
	install -m 0644    ${WORKDIR}/mdev.conf	${D}${sysconfdir}/mdev.conf
	install -m 0755    ${WORKDIR}/usb.sh	${D}${sysconfdir}/mdev/usb.sh
	install -m 0755    ${WORKDIR}/find-touchscreen.sh	${D}${sysconfdir}/mdev/find-touchscreen.sh
	install -m 0644    ${WORKDIR}/functions		${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/bootmisc.sh	${D}${sysconfdir}/init.d
	if [ "${MACHINE}" = "swi-mdm9x15" ]; then
		install -m 0755    ${WORKDIR}/bringup_ecm.sh	${D}${sysconfdir}/init.d
		install -m 0755    ${WORKDIR}/bridge_ecm.sh	${D}${sysconfdir}/init.d
	fi
	install -m 0755    ${WORKDIR}/mountall.sh	${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/single		${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/urandom		${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/devpts		${D}${sysconfdir}/default
	install -m 0644    ${WORKDIR}/volatiles		${D}${sysconfdir}/default/volatiles/00_core
	install -m 0755    ${WORKDIR}/rcS			${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/rcK			${D}${sysconfdir}/init.d

	if [ "${TARGET_ARCH}" = "arm" ]; then
		install -m 0755 ${WORKDIR}/alignment.sh	${D}${sysconfdir}/init.d
	fi

#
# Remove some scripts
#
	[ -n "${D}" ] && OPT="-r ${D}" || OPT="-s"
	update-rc.d $OPT -f sysfs.sh remove

#
# Create runlevel links
#
        update-rc.d -r ${D} urandom start 08 S .
        update-rc.d -r ${D} mountall.sh start 07 S .
        update-rc.d -r ${D} bootmisc.sh start 55 S .
	if [ "${MACHINE}" = "swi-mdm9x15" ]; then
	        update-rc.d -r ${D} bringup_ecm.sh start 95 S .
	fi

	if [ "${TARGET_ARCH}" = "arm" ]; then
	        update-rc.d -r ${D} alignment.sh start 06 S .
	fi
}
