FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15  = "standard/preempt-rt/swi-mdm9x15"

KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto-rt_swi-mdm9x15 ?= "1debe43e6524e35d7d8710f48e1d4638599e8dea"
SRCREV_meta_pn-linux-yocto-rt_swi-mdm9x15 ?= "41f2a391ac4b0fe4cb0d4697f36756caf8739507"
