FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.4.91"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15  = "standard/swi-mdm9x15-yocto-1.6"

# KSRC_linux_yocto_3_4 := "${LINUX_REPO_DIR}"
KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta-yocto-1.6;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "e207cfc00f76a94cf2019fca4934716172c82526"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "afcf840dce6beb93b8a05ee04d5a8bf5b2a4666c"
