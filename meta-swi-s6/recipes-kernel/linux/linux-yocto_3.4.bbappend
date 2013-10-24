FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-s6 = "swi-s6"
KBRANCH_swi-s6  = "standard/swi-s6"

KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto_swi-s6 ?= "12473c86db16cc38c26cc6a9224b66a45d4312b2"
SRCREV_meta_pn-linux-yocto_swi-s6 ?= "919d77ed32aeb051a37231aee1ff727c941d1b44"
