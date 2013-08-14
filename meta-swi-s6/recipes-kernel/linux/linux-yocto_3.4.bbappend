FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

PR := "${PR}.1"

COMPATIBLE_MACHINE_swi-s6 = "swi-s6"

SRCREV_machine_pn-linux-yocto_swi-s6 ?= "${AUTOREV}"
SRCREV_meta_pn-linux-yocto_swi-s6 ?= "${AUTOREV}"
