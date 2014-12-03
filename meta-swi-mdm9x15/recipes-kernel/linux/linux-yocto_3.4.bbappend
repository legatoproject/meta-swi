FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.4.91"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15 = "standard/swi-mdm9x15-yocto-1.6-swi"
KMETA = "meta-yocto-1.6-swi"

KSRC_linux_yocto_3_4 := "${LINUX_REPO_DIR}"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

# Use latest commits from KBRANCH & KMETA
SRCREV_machine_swi-mdm9x15 = "${AUTOREV}"
SRCREV_meta_swi-mdm9x15 = "${AUTOREV}"
