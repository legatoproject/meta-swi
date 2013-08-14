FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " file://0001-enable-ykem-board.patch \
	file://0002-enable-CPU-mailbox-and-virtual-mtd_com-features.patch \
	file://0003-mtd-cfi_flash-fix-write-problems.patch"
