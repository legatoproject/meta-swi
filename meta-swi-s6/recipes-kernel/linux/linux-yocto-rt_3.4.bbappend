FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-s6 = "swi-s6"
KBRANCH_swi-s6  = "standard/preempt-rt/swi-s6"

KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto-rt_swi-s6 ?= "777263547ba7124c3a3b8b84a6c49e5284258058"
SRCREV_meta_pn-linux-yocto-rt_swi-s6 ?= "919d77ed32aeb051a37231aee1ff727c941d1b44"
