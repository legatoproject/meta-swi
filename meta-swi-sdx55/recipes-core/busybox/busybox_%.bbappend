FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Override busybox configuration for systemd operation
SRC_URI += "${@bb.utils.contains('DISTRO_FEATURES', "systemd","\
            file://find-touchscreen.sh \
            file://automountsdcard.sh \
            file://usb.sh \
            file://mdev.conf \
            file://profile \
            file://fstab \
            file://inittab \
            file://rcS \
            file://no-console.cfg \
            file://login.cfg \
            file://mdev.cfg \
            file://base.cfg \
            file://syslog-startup.conf \
            file://busybox-syslog.service \
            file://iio.sh \
            file://0001-Support-MTP-function.patch \
            file://fix-mdev-crash.patch \
            file://sensors.sh \
",'', d)}"

SRC_URI_append_apq8053 += "file://apq8053/mdev.conf"

FILES_${PN}-syslog += "${@bb.utils.contains('DISTRO_FEATURES', "systemd","${systemd_unitdir}/system/busybox-klogd.service ${systemd_unitdir}/system/multi-user.target.wants/busybox-syslog.service",'', d)}"

BUSYBOX_SPLIT_SUID = "0"
FILES_${PN} += "/usr/bin/env"

do_install_append() {
    # systemd is udev compatible.
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${sysconfdir}/udev/scripts/
        install -m 0744 ${WORKDIR}/automountsdcard.sh \
            ${D}${sysconfdir}/udev/scripts/automountsdcard.sh
        install -d ${D}${systemd_unitdir}/system/
        install -m 0644 ${WORKDIR}/busybox-syslog.service -D ${D}${systemd_unitdir}/system/busybox-syslog.service
        install -d ${D}${systemd_unitdir}/system/multi-user.target.wants/
        # enable the service for multi-user.target
        ln -sf ${systemd_unitdir}/system/busybox-syslog.service \
           ${D}${systemd_unitdir}/system/multi-user.target.wants/busybox-syslog.service
        install -d ${D}${sysconfdir}/initscripts
        install -m 0755 ${WORKDIR}/syslog ${D}${sysconfdir}/initscripts/syslog
        sed -i 's/syslogd -- -n/syslogd -n/' ${D}${sysconfdir}/initscripts/syslog
        sed -i 's/init.d/initscripts/g'  ${D}${systemd_unitdir}/system/busybox-syslog.service
    fi

    mkdir -p ${D}/usr/bin
    ln -s /bin/env ${D}/usr/bin/env
}

# util-linux installs dmesg with priority 80. Use higher priority than util-linux to get busybox dmesg installed.
ALTERNATIVE_PRIORITY[dmesg] = "100"

#FILES_${PN}-mdev += "${sysconfdir}/mdev/* "
