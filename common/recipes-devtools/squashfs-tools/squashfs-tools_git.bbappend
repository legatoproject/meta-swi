
PV = "4.3+gitr${SRCPV}"
SRCREV = "9c1db6d13a51a2e009f0027ef336ce03624eac0d"
SRC_URI = "git://github.com/plougher/squashfs-tools.git;protocol=https \
           file://squashfs-tools-4.3-sysmacros.patch;striplevel=2 \
           file://0001-squashfs-tools-patch-for-CVE-2015-4645-6.patch;striplevel=2 \
"
