# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI = "file://functions \
           file://devpts \
           file://hostname.sh \
           file://mountall.sh \
           file://banner.sh \
           file://bootmisc.sh \
           file://checkfs.sh \
           file://single \
           file://urandom \
           file://rmnologin.sh \
           file://volatiles \
           file://save-rtc.sh \
           file://inittab \
           file://mdev.conf \
           file://usb.sh \
           file://find-touchscreen.sh \
           file://rcS \
           file://rcK \
           file://bootmisc.sh \
           file://GPLv2.patch \
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
	install -m 0755    ${WORKDIR}/hostname.sh	${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/mountall.sh	${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/rmnologin.sh	${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/single		${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/urandom		${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/devpts		${D}${sysconfdir}/default
	install -m 0755    ${WORKDIR}/save-rtc.sh	${D}${sysconfdir}/init.d
	install -m 0644    ${WORKDIR}/volatiles		${D}${sysconfdir}/default/volatiles/00_core
	install -m 0755    ${WORKDIR}/rcS			${D}${sysconfdir}/init.d
	install -m 0755    ${WORKDIR}/rcK			${D}${sysconfdir}/init.d

	if [ "${TARGET_ARCH}" = "arm" ]; then
		install -m 0755 ${WORKDIR}/alignment.sh	${D}${sysconfdir}/init.d
	fi
#
# Install device dependent scripts
#
	install -m 0755 ${WORKDIR}/banner.sh	${D}${sysconfdir}/init.d/banner.sh

#
# Remove some scripts
#
	[ -n "${D}" ] && OPT="-r ${D}" || OPT="-s"
	update-rc.d $OPT -f sysfs.sh remove

#
# Create runlevel links
#
	update-rc.d -r ${D} rmnologin.sh start 98 S .
	update-rc.d -r ${D} urandom start 08 S .
	update-rc.d -r ${D} save-rtc.sh start 25 S .
	update-rc.d -r ${D} banner.sh start 02 S .
	update-rc.d -r ${D} mountall.sh start 07 S .
	update-rc.d -r ${D} hostname.sh start 39 S .
	update-rc.d -r ${D} bootmisc.sh start 55 S .
	if [ "${TARGET_ARCH}" = "arm" ]; then
	        update-rc.d -r ${D} alignment.sh start 06 S .
	fi
}
