FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.4.91"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_swi-mdm9x15  = "standard/preempt-rt/swi-mdm9x15-yocto-1.6"

# KSRC_linux_yocto_3_4 := "${LINUX_REPO_DIR}"
KSRC_linux_yocto_3_4 := "${THISDIR}/../../../../linux-yocto-3.4.git"
SRC_URI = "git://${KSRC_linux_yocto_3_4};protocol=file;branch=${KBRANCH},meta-yocto-1.6;name=machine,meta"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto-rt_swi-mdm9x15 = "d2cd1fb8175db4f41772f8329040163395a7ae5f"
SRCREV_meta_pn-linux-yocto-rt_swi-mdm9x15 = "c38512ba8ee5b7dbd0049f09c164b374fc4bf2b4"
