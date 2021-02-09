###############################################################################
# Author: Dragan Marinkovic (dmarinkovi@sierrawireless.com)
# Copyright (c) 2020, Sierra Wireless Inc. All rights reserved.
###############################################################################
# audiodlkm_git.bb is the original file copied from QCOM's mdm9x28 release
# and it should not be touched. If something needs to be done, it needs to
# happen here.
# audiodlkm adds number of kernel modules required for MSM audio to operate
# properly. Starting with QCOM kernels after 3.18, audio was moved out of Linux
# kernel source tree and MSM audio functionality is supported via out-of-tree
# kernel modules.
# #############################################################################

# QCOM kernel MSM audio sources are located at code Aurora
SRCREV = "859fcc26b5c49f889fc0a2f7b7fadcbcba80ab0e"
SRC_REPO = "git://codeaurora.org/platform/vendor/opensource/audio-kernel;branch=LE.UM.3.4.2.r1.9"
PR = "r0"
FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-files:"
SRC_URI = "${SRC_REPO}"
S = "${WORKDIR}/git"
BASEMACHINE = "${BASEMACHINE_QCOM}"
KERN_VERS_ACCEPTABLE = "4.14%"

# Additional files
SRC_URI_FILES += " \
                   file://start_audio_le \
                   file://load_audio_base \
                   file://wm8944.c \
                   file://wm8944.h \
                 "
# Patches
SRC_URI_PATCHES += " \
                    file://0001-makefile.patch \
                    file://0002-compile-errors.patch \
                    file://0003-config.patch \
                    file://0004-source-changes.patch \
                    file://0005-source-changes.patch \
                    file://0006-source-changes.patch \
                    file://0007-source-changes.patch \
                    file://0008-source-changes.patch \
                    file://0009-source-changes.patch \
                    file://0010-source-changes.patch \
                    file://0011-source-changes.patch \
                    file://0012-source-changes.patch \
                    file://0013-source-changes.patch \
                    file://0014-source-changes.patch \
                    file://0015-source-changes.patch \
                    file://0016-source-changes.patch \
                    file://0017-source-changes.patch \
                   "

# Add it all together
SRC_URI += "${SRC_URI_FILES} ${SRC_URI_PATCHES}"

# Clear it
INITSCRIPT_NAME = ""
INITSCRIPT_PARAMS = ""

# Enable mdm9607-audio-tomtom. If you do, it will
# take over the resources, and mdm9607-audio-wm8944
# would not work.
# KERNEL_CC += "-DMDM9607_AUDIO_TOMTOM"

# Use update-rc.d directly here.
DEPENDS_append = " update-rc.d-native"

do_unpack[deptask] = "do_populate_sysroot"

# Do not execute
do_install_append_mdm[noexec] = "1"

# Under normal circumstances audiodlkm would not be included
# into final rootfs image if kernel version does not match.
# However, we should prevent time waste if someone tries to
# "bitbake" this package on its own, and required kernel
# version does not match with base system requirements.
do_fetch_prepend() {

    kernel_provider = d.getVar("PREFERRED_PROVIDER_virtual/kernel", True)
    kernel_version = d.getVar('PREFERRED_VERSION_%s' % kernel_provider, True)
    kernel_vers_acceptable = d.getVar('KERN_VERS_ACCEPTABLE', True)
    if kernel_version != kernel_vers_acceptable:
        bb.fatal("This kernel module does not work with kernel ", kernel_vers_acceptable)
        exit(1)
}

# Make sure Makefile and all other files exist.
do_configure() {
	cp -f ${WORKDIR}/git/Makefile.am ${WORKDIR}/git/Makefile
	cp -f ${WORKDIR}/wm8944.{c,h} ${WORKDIR}/git/asoc/codecs/.
}

# This is here in order to add to whatever is in audiodlkm_git.bb:do_install_append()
# so we do not have to have same code in two places. It will be added __after__ the
# content of audiodlkm_git.bb:do_install_append() .
do_install_append() {

	install -d ${D}${sysconfdir}/init.d

	install -m 0755 ${WORKDIR}/start_audio_le ${D}${sysconfdir}/init.d/start_audio_le
	install -m 0755 ${WORKDIR}/load_audio_base ${D}${sysconfdir}/init.d/load_audio_base
}

# Delayed: Will execute at the time of rootfs installation
pkg_postinst_${PN}() {

	[ -n "$D" ] && OPT="-r $D" || OPT="-s"

	update-rc.d $OPT -f start_audio_le remove
	update-rc.d $OPT start_audio_le start 28 S . stop 71 S .

	update-rc.d $OPT -f load_audio_base remove
	update-rc.d $OPT load_audio_base start 27 S . stop 72 S .

}

# DM, FIXME: Remove this override once audio is fully working.
# pkg_postinst_${PN}() {
#	:
# }

# The inherit of module.bbclass will automatically name module packages with
# kernel-module-" prefix as required by the oe-core build environment. Also it
# replaces '_' with '-' in the module name. So, if a module name is apr_dlkm.ko,
# we will have to add to this list the following name:
#       kernel-module-apr-dlkm-${KERNEL_VERSION}
# Otherwise, bitbake would complain that nothing provides
# kernel-module-apr-dlkm-${KERNEL_VERSION}, even though this kernel module
# really exists.
RPROVIDES_${PN} += "\
	kernel-module-apr-dlkm-${KERNEL_VERSION} \
	kernel-module-adsp-loader-dlkm-${KERNEL_VERSION} \
	kernel-module-q6-dlkm-${KERNEL_VERSION} \
	kernel-module-platform-dlkm-${KERNEL_VERSION} \
	kernel-module-stub-dlkm-${KERNEL_VERSION} \
	kernel-module-wcd-core-dlkm-${KERNEL_VERSION} \
	kernel-module-wcd-cpe-dlkm-${KERNEL_VERSION} \
	kernel-module-wcd9330-dlkm-${KERNEL_VERSION} \
	kernel-module-machine-dlkm-${KERNEL_VERSION} \
	kernel-module-wm8944-dlkm-${KERNEL_VERSION} \
	"
