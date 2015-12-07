# Tag M9615AAAARNLZA1713041
SRCREV = "08811d0dc64c490e94aa0f5f0e97f19fef1d1e7e"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0000-mdm9x15-Import-SWI-changes.patch"
SRC_URI += "file://0002-TRAC-1223-lk-make_sure_that_Yocto_kernel_receives_correct_atag_MTD_partition_information_from_bootloader.patch"
SRC_URI += "file://0003-SBM-14659-Modem-cannot-bootup-after-flash-customer-Yocto-image-with-fastboot.patch"
SRC_URI += "file://0004-SBM-15385-GPIO-cooperation-mode-support.patch"
SRC_URI += "file://0005-SBM-15691-support-squashfs-download.patch"
SRC_URI += "file://0006-SBM-17249-support-ubi-download.patch"
SRC_URI += "file://0007-TRAC-2357-LK-version.patch"
SRC_URI += "file://0008-SBM-16707-lk-debug-msg-on-uart.patch"
SRC_URI += "file://0009-TRAC-2623-Provide-sysroot-to-gcc-and-ld.patch"
SRC_URI += "file://0010-TRAC-2797-WP85-support-and-fastboot-support-for-user1-partition.patch"
SRC_URI += "file://0011-TRAC-3105-LK-set-quiet-option.patch"
SRC_URI += "file://0012-Deliver-appsboot.-to-BUILDDIR.patch"

LK_TARGET = "mdm9615"
