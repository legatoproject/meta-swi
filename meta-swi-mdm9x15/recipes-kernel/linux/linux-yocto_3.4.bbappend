FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15  = "standard/swi-mdm9x15"

KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "18154361da35288e2e30690acb3f5a0a4f79cc34"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "41f2a391ac4b0fe4cb0d4697f36756caf8739507"
