FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.4.91"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"

KBRANCH_DEFAULT_MDM9X15 ?= "standard/preempt-rt/swi-mdm9x15-yocto-1.6"
KBRANCH_swi-mdm9x15 = "${KBRANCH_DEFAULT_MDM9X15}"

KMETA_DEFAULT_MDM9X15 ?= "meta-yocto-1.6-swi"
KMETA = "${KMETA_DEFAULT_MDM9X15}"

KSRC_linux_yocto_3_4 := "${LINUX_REPO_DIR}"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

# Use latest commits from KBRANCH & KMETA
SRCREV_machine_swi-mdm9x15 = "${AUTOREV}"
SRCREV_meta_swi-mdm9x15 = "${AUTOREV}"

