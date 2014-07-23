FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION ?= "3.4.91"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15  = "standard/swi-mdm9x15-yocto-1.6"

KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta-yocto-1.6;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "30c5a3aec7e43dc8c3a37a4e9334416bdf80aed0"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "94c86fbee738b519e906047bdbb6bd4c4aaafdc2"
