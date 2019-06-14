FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://Disable-unused-mount-points.patch"
SRC_URI += "file://mountpartitions.rules"
SRC_URI += "file://systemd-udevd.service"
SRC_URI += "file://ffbm.target"
SRC_URI += "file://mtpserver.rules"
SRC_URI += "file://sysctl-core.conf"
SRC_URI += "file://limit-core.conf"
SRC_URI += "file://logind.conf"
SRC_URI += "file://ion.rules"
SRC_URI += "file://kgsl.rules"
SRC_URI += "file://set-usb-nodes.rules"
SRC_URI += "file://sysctl.conf"
SRC_URI += "file://platform.conf"

# Custom setup for PACKAGECONFIG to get a slimmer systemd.
# Removed following:
#   * backlight - Loads/Saves Screen Backlight Brightness, not required.
#   * firstboot - initializes the most basic system settings interactively
#                  on the first boot if /etc is empty, not required.
#   * hostname  - No need to change the system's hostname
#   * ldconfig  - configures dynamic linker run-time bindings.
#                 ldconfig  creates  the  necessary links and cache to the most
#                 recent shared libraries found in the directories specified on
#                 the command line, in the file /etc/ld.so.conf, and in the
#                 trusted directories (/lib and /usr/lib).  The cache (created
#                 at /etc/ld.so.cache) is used by the run-time linker ld-linux.so.
#                 system-ldconfig.service runs "ldconfig -X", but as / is RO
#                 cache may not be created. Disabling this may introduce app
#                 start time latency.
#   * localed   - Service used to change the system locale settings, not needed.
#   * machined  - For tracking local Virtual Machines and Containers, not needed.
#   * networkd  - Manages network configurations, custom solution is used.
#   * quotacheck- Not using Quota.
#   * resolvd   - Use custom network name resolution manager.
#   * smack     - Not used.
#   * timesyncd - Chronyd is being used instead for NTP timesync.
#                 Also timesyncd was resulting in higher boot KPI.
#   * utmp      - No back fill for SysV runlevel changes needed.
#   * vconsole  - Not used.
PACKAGECONFIG = " \
    ${@bb.utils.filter('DISTRO_FEATURES', 'selinux', d)} \
    ${@bb.utils.contains('DISTRO_FEATURES', 'wifi', 'rfkill', '', d)} \
    acl \
    binfmt \
    hibernate \
    hostnamed \
    ima \
    kmod \
    logind \
    polkit \
    randomseed \
    sysusers \
    timedated \
    xz \
"
EXTRA_OEMESON += " -Defi=false"
EXTRA_OEMESON += " -Dhwdb=false"

CFLAGS_append = " -fPIC"

# In aarch64 targets systemd is not booting with -finline-functions -finline-limit=64 optimizations
# So temporarily revert to default optimizations for systemd.
SELECTED_OPTIMIZATION = "-O2 -fexpensive-optimizations -frename-registers -fomit-frame-pointer -ftree-vectorize"

MACHINE_COREDUMP_ENABLE = "${@bb.utils.contains_any('BASEMACHINE', 'qcs605 sdmsteppe', 'true', 'false', d)}"

# Place systemd-udevd.service in /etc/systemd/system
do_install_append () {

   if [ "${MACHINE_COREDUMP_ENABLE}" == "true" ]; then
       sed -i "s#var\/tmp#data\/coredump#g" ${WORKDIR}/sysctl-core.conf
       #create coredump folder in data
       install -d ${D}${userfsdatadir}/coredump
   fi
   install -d ${D}/etc/systemd/system/
   install -d ${D}/lib/systemd/system/ffbm.target.wants
   install -d ${D}/etc/systemd/system/ffbm.target.wants
   rm ${D}/lib/udev/rules.d/60-persistent-v4l.rules
   install -m 0644 ${WORKDIR}/systemd-udevd.service \
       -D ${D}/etc/systemd/system/systemd-udevd.service
   install -m 0644 ${WORKDIR}/ffbm.target \
       -D ${D}/etc/systemd/system/ffbm.target
   # Enable logind/getty/password-wall service in FFBM mode
   ln -sf /lib/systemd/system/systemd-logind.service ${D}/lib/systemd/system/ffbm.target.wants/systemd-logind.service
   ln -sf /lib/systemd/system/getty.target ${D}/lib/systemd/system/ffbm.target.wants/getty.target
   ln -sf /lib/systemd/system/systemd-ask-password-wall.path ${D}/lib/systemd/system/ffbm.target.wants/systemd-ask-password-wall.path
   install -d ${D}/etc/security/limits.d/
   install -m 0644 ${WORKDIR}/limit-core.conf -D ${D}/etc/security/limits.d/core.conf
   install -d /etc/sysctl.d/
   install -m 0644 ${WORKDIR}/sysctl-core.conf -D ${D}/etc/sysctl.d/core.conf
   install -m 0644 ${WORKDIR}/sysctl.conf -D ${D}/etc/sysctl.d/sysctl.conf
   install -m 0644 ${WORKDIR}/logind.conf -D ${D}/etc/systemd/logind.conf
   install -m 0644 ${WORKDIR}/platform.conf -D ${D}/etc/tmpfiles.d/platform.conf
   #  Mask journaling services by default.
   #  'systemctl unmask' can be used on device to enable them if needed.
   ln -sf /dev/null ${D}/etc/systemd/system/systemd-journald.service
   ln -sf /dev/null ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-flush.service
   ln -sf /dev/null ${D}${systemd_unitdir}/system/sysinit.target.wants/systemd-journal-catalog-update.service
   install -d ${D}${sysconfdir}/udev/rules.d/
   install -m 0644 ${WORKDIR}/ion.rules -D ${D}${sysconfdir}/udev/rules.d/ion.rules
   install -m 0644 ${WORKDIR}/kgsl.rules -D ${D}${sysconfdir}/udev/rules.d/kgsl.rules
   # Mask dev-ttyS0.device
   ln -sf /dev/null ${D}/etc/systemd/system/dev-ttyS0.device
}

# Run fsck as part of local-fs-pre.target instead of local-fs.target
do_install_append () {
   # remove from After
   sed -i '/After/s/local-fs-pre.target//' ${D}${systemd_unitdir}/system/systemd-fsck@.service
   # Add to Before
   sed -i '/Before/s/$/ local-fs-pre.target/' ${D}${systemd_unitdir}/system/systemd-fsck@.service
}

RRECOMMENDS_${PN}_remove += "systemd-extra-utils"
PACKAGES_remove += "${PN}-extra-utils"

do_install_append_robot-som-ros () {
    rm ${D}/etc/sysctl.d/core.conf
}

PACKAGES +="${PN}-coredump"
FILES_${PN} += "/etc/initscripts \
                ${sysconfdir}/udev/rules.d ${userfsdatadir}/*"
FILES_${PN}-coredump = "/etc/sysctl.d/core.conf /etc/security/limits.d/core.conf  ${userfsdatadir}/coredump"
