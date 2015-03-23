FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

LINUX_VERSION = "3.14.29"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"
KBRANCH_DEFAULT = "standard/swi-mdm9x15-yocto-1.7"
KBRANCH = "${KBRANCH_DEFAULT}"
KMETA="meta-yocto-1.7"

KSRC_linux_yocto_3_14 := "${THISDIR}/../../../../linux-yocto-3.14"
SRC_URI = "git://${KSRC_linux_yocto_3_14};protocol=file;branch=${KBRANCH},${KMETA};name=machine,meta"

COMPATIBLE_MACHINE_swi-mdm9x15 = "(swi-mdm9x15)"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine = "${SRCREV}"
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "${AUTOREV}"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "${AUTOREV}"

do_patch_prepend(){
	if [ "${KBRANCH}" != "standard/base" ]; then
		updateme_flags="--branch ${KBRANCH}"
	fi
}
