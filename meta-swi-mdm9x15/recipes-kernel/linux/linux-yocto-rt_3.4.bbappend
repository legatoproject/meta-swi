FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15  = "standard/preempt-rt/swi-mdm9x15"

KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto-rt_swi-mdm9x15 ?= "864a82da383b7b24349a71789e547325cc14c018"
SRCREV_meta_pn-linux-yocto-rt_swi-mdm9x15 ?= "2e61d6fe5f1fbf6e1e2cca78e0a61c5e37c9cc78"
