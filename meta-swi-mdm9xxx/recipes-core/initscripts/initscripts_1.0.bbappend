# look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR="r157"

SRC_URI = "file://functions \
           file://devpts \
           file://mountall.sh \
           file://hostname.sh \
           file://bootmisc.sh \
           file://bringup_ecm.sh \
           file://bridge_ecm.sh \
           file://checkfs.sh \
           file://single \
           file://urandom \
           file://volatiles \
           file://mdev.conf \
           file://usb.sh \
           file://find-touchscreen.sh \
           file://rcS \
           file://rcK \
           file://GPLv2.patch \
           file://confighw.sh \
           file://swiapplaunch.sh.in \
           file://restart_swi_apps.in \
           file://restartNMEA \
           file://run.env.in \
           file://run_getty.sh.in \
           file://mount_early.in \
           file://loginNagger \
           file://load_modem.sh \
           file://accesses \
           file://ecm.conf.in \
           file://dnsmasq.ecm.conf.in \
           "

SRC_URI_swi-mdm9x28-ar758x-rcy = "file://functions \
           file://devpts \
           file://mountall.sh \
           file://bootmisc.sh \
           file://bringup_ecm.sh \
           file://bridge_ecm.sh \
           file://checkfs.sh \
           file://single \
           file://urandom \
           file://volatiles \
           file://mdev.conf \
           file://usb.sh \
           file://find-touchscreen.sh \
           file://rcS \
           file://rcK \
           file://GPLv2.patch \
           file://run.env.in \
           file://run_getty.sh.in \
           file://control_msm_watchdog.sh \
           "

SRC_URI_swi-mdm9x40-ar759x-rcy = "file://functions \
           file://devpts \
           file://mountall.sh \
           file://bootmisc.sh \
           file://bringup_ecm.sh \
           file://bridge_ecm.sh \
           file://checkfs.sh \
           file://single \
           file://urandom \
           file://volatiles \
           file://mdev.conf \
           file://usb.sh \
           file://find-touchscreen.sh \
           file://rcS \
           file://rcK \
           file://GPLv2.patch \
           file://run.env.in \
           file://run_getty.sh.in \
           file://control_msm_watchdog.sh \
           "

SRC_URI_append_swi-mdm9x28 = "\
           file://restart_at_uart \
           "

SRC_URI_append_swi-mdm9x28-ar758x = "\
           file://restart_at_uart \
           file://control_msm_watchdog.sh \
           "

SRC_URI_append_swi-mdm9x40-ar759x = "\
           file://restart_at_uart \
           file://control_msm_watchdog.sh \
           "

SRC_URI_append_arm = " file://alignment.sh"

KERNEL_VERSION = ""

inherit update-alternatives
DEPENDS_append = " update-rc.d-native"

HALTARGS ?= "-d -f"

do_configure () {
}

do_install () {

    process_templates

    #
    # Create directories and install device independent scripts
    #
    install -d ${D}${sysconfdir}/mdev
    install -d ${D}${sysconfdir}/init.d
    install -d ${D}${sysconfdir}/default
    install -d ${D}${sysconfdir}/default/volatiles
    # Holds state information pertaining to urandom
    install -d ${D}/var/lib/urandom
    install -d ${D}${sysconfdir}/qct_cfg

    install -m 0644    ${WORKDIR}/mdev.conf ${D}${sysconfdir}/mdev.conf
    install -m 0755    ${WORKDIR}/usb.sh    ${D}${sysconfdir}/mdev/usb.sh
    install -m 0755    ${WORKDIR}/find-touchscreen.sh   ${D}${sysconfdir}/mdev/find-touchscreen.sh
    install -m 0644    ${WORKDIR}/accesses -D ${D}${sysconfdir}/smack/accesses
    install -m 0644    ${WORKDIR}/functions     ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bootmisc.sh   ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/hostname.sh   ${D}${sysconfdir}/init.d
    if [ "${MACHINE}" != "swi-mdm9x28-ar758x" ] && [ "${MACHINE}" != "swi-mdm9x28-ar758x-qemu" ] && [ "${MACHINE}" != "swi-mdm9x40-ar759x" ]; then
        install -m 0755    ${WORKDIR}/bringup_ecm.sh    ${D}${sysconfdir}/init.d
        install -m 0755    ${WORKDIR}/bridge_ecm.sh ${D}${sysconfdir}/init.d
    fi
    install -m 0755    ${WORKDIR}/mountall.sh   ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/single        ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/urandom       ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/devpts        ${D}${sysconfdir}/default
    install -m 0644    ${WORKDIR}/volatiles     ${D}${sysconfdir}/default/volatiles/00_core
    install -m 0755    ${WORKDIR}/rcS           ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/rcK           ${D}${sysconfdir}/init.d

    if [ "${TARGET_ARCH}" = "arm" ]; then
        install -m 0755 ${WORKDIR}/alignment.sh ${D}${sysconfdir}/init.d
    fi

    install -m 0755 ${WORKDIR}/confighw.sh -D ${D}${sysconfdir}/init.d/confighw.sh
    install -m 0755 ${WORKDIR}/swiapplaunch.sh -D ${D}${sysconfdir}/init.d/swiapplaunch.sh
    if [[ "${MACHINE}" == "swi-mdm"* ]]; then
        install -m 0755 ${WORKDIR}/restart_swi_apps -D ${D}${sbindir}/restart_swi_apps
    fi
    install -m 0755 ${WORKDIR}/restartNMEA -D ${D}${sbindir}/restartNMEA
    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env
    install -m 0755 ${WORKDIR}/run_getty.sh -D ${D}${sbindir}/run_getty.sh


    install -D -m 0755 ${WORKDIR}/mount_unionfs -D ${D}${sysconfdir}/init.d/mount_unionfs
    install -D -m 0755 ${WORKDIR}/mount_early -D ${D}${sysconfdir}/init.d/mount_early
    install -D -m 0755 ${WORKDIR}/load_modem.sh -D ${D}${sysconfdir}/init.d/load_modem.sh

    # profile.d is currently empty, and to avoid /etc/profile from complaining
    # an empty profile.d dir, the below line is commented out.
    #install -d -m 0755 ${D}${sysconfdir}/profile.d
    install -m 0755 ${WORKDIR}/loginNagger -D ${D}${sbindir}/loginNagger

    case "${MACHINE}" in
    swi-mdm9x28 | swi-mdm9x28-qemu)
        install -m 0755 ${WORKDIR}/restart_at_uart -D ${D}${sbindir}/restart_at_uart
        ;;
    swi-mdm9x28-ar758x | swi-mdm9x28-ar758x-qemu | swi-mdm9x40-ar759x)
        install -m 0755 ${WORKDIR}/control_msm_watchdog.sh -D ${D}${sysconfdir}/init.d/control_msm_watchdog.sh
        install -m 0755 ${WORKDIR}/restart_at_uart -D ${D}${sbindir}/restart_at_uart
        ;;
    esac

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
    if [ "${MACHINE}" != "swi-mdm9x28-ar758x" ] && [ "${MACHINE}" != "swi-mdm9x28-ar758x-qemu" ] && [ "${MACHINE}" != "swi-mdm9x40-ar759x" ]; then
        update-rc.d -r ${D} bringup_ecm.sh start 95 S .
    fi
    if [ "${TARGET_ARCH}" = "arm" ]; then
        update-rc.d -r ${D} alignment.sh start 06 S .
    fi

    update-rc.d $OPT -f mount_early remove
    update-rc.d $OPT mount_early start 02 S . stop 98 S .
    update-rc.d $OPT -f confighw.sh remove
    update-rc.d $OPT confighw.sh start 03 S .
    update-rc.d $OPT -f mount_unionfs remove
    update-rc.d $OPT mount_unionfs start 04 S . stop 96 S .
    update-rc.d $OPT -f hostname.sh remove
    update-rc.d $OPT hostname.sh start 10 S .
    update-rc.d $OPT -f swiapplaunch.sh remove
    update-rc.d $OPT swiapplaunch.sh start 31 S . stop 69 S .
    update-rc.d $OPT load_modem.sh start 09 S . stop 90 S .
}

do_install_append() {
    # Change root's default shell from /bin/sh to /usr/sbin/loginNagger
    # FIXME: KeLiu:
    # This line should be in do_install(). However, putting it there
    # results a build failure where sed complains the passwd file does not
    # exist. Leaving it in do_install_append() for now.
    sed -i 's#\(root:x:0:0:.*\):/bin/.*sh#\1:/usr/sbin/loginNagger#' ${D}${sysconfdir}/passwd
}

do_install_swi-mdm9x28-ar758x-rcy() {

    process_templates

    #
    # Create directories and install device independent scripts
    #
    install -d ${D}${sysconfdir}/mdev
    install -d ${D}${sysconfdir}/init.d
    install -d ${D}${sysconfdir}/default
    install -d ${D}${sysconfdir}/default/volatiles
    # Holds state information pertaining to urandom
    install -d ${D}/var/lib/urandom

    install -m 0644    ${WORKDIR}/mdev.conf ${D}${sysconfdir}/mdev.conf
    install -m 0755    ${WORKDIR}/usb.sh    ${D}${sysconfdir}/mdev/usb.sh
    install -m 0755    ${WORKDIR}/find-touchscreen.sh   ${D}${sysconfdir}/mdev/find-touchscreen.sh
    install -m 0644    ${WORKDIR}/functions     ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bootmisc.sh   ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bringup_ecm.sh    ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bridge_ecm.sh ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/mountall.sh   ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/single        ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/urandom       ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/devpts        ${D}${sysconfdir}/default
    install -m 0644    ${WORKDIR}/volatiles     ${D}${sysconfdir}/default/volatiles/00_core
    install -m 0755    ${WORKDIR}/rcS           ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/rcK           ${D}${sysconfdir}/init.d

    if [ "${TARGET_ARCH}" = "arm" ]; then
        install -m 0755 ${WORKDIR}/alignment.sh ${D}${sysconfdir}/init.d
    fi

    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env
    install -m 0755 ${WORKDIR}/run_getty.sh -D ${D}${sbindir}/run_getty.sh
    install -m 0755 ${WORKDIR}/control_msm_watchdog.sh -D ${D}${sysconfdir}/init.d/control_msm_watchdog.sh
}

do_install_swi-mdm9x40-ar759x-rcy() {

    process_templates

    #
    # Create directories and install device independent scripts
    #
    install -d ${D}${sysconfdir}/mdev
    install -d ${D}${sysconfdir}/init.d
    install -d ${D}${sysconfdir}/default
    install -d ${D}${sysconfdir}/default/volatiles
    # Holds state information pertaining to urandom
    install -d ${D}/var/lib/urandom

    install -m 0644    ${WORKDIR}/mdev.conf ${D}${sysconfdir}/mdev.conf
    install -m 0755    ${WORKDIR}/usb.sh    ${D}${sysconfdir}/mdev/usb.sh
    install -m 0755    ${WORKDIR}/find-touchscreen.sh   ${D}${sysconfdir}/mdev/find-touchscreen.sh
    install -m 0644    ${WORKDIR}/functions     ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bootmisc.sh   ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bringup_ecm.sh    ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/bridge_ecm.sh ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/mountall.sh   ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/single        ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/urandom       ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/devpts        ${D}${sysconfdir}/default
    install -m 0644    ${WORKDIR}/volatiles     ${D}${sysconfdir}/default/volatiles/00_core
    install -m 0755    ${WORKDIR}/rcS           ${D}${sysconfdir}/init.d
    install -m 0755    ${WORKDIR}/rcK           ${D}${sysconfdir}/init.d

    if [ "${TARGET_ARCH}" = "arm" ]; then
        install -m 0755 ${WORKDIR}/alignment.sh ${D}${sysconfdir}/init.d
    fi

    install -m 0444 ${WORKDIR}/run.env -D ${D}${sysconfdir}/run.env
    install -m 0755 ${WORKDIR}/run_getty.sh -D ${D}${sbindir}/run_getty.sh
    install -m 0755 ${WORKDIR}/control_msm_watchdog.sh -D ${D}${sysconfdir}/init.d/control_msm_watchdog.sh
}
