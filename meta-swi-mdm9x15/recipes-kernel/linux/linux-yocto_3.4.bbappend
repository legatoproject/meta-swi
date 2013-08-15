FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-mdm9x15 = "swi-mdm9x15"

# uncomment and replace these SRCREVs with the real commit ids once you've had
# the appropriate changes committed to the upstream linux-yocto repo
SRCREV_machine_pn-linux-yocto_swi-mdm9x15 ?= "3a7402ad4eee466b09905810208d922e70f4336d"
SRCREV_meta_pn-linux-yocto_swi-mdm9x15 ?= "d8ad68de7dd56edd1cbde8e69db07f0f1b43a2e2"
