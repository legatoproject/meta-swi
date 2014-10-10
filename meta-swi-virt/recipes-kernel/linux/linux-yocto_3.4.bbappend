COMPATIBLE_MACHINE_swi-virt = "swi-virt"

KMACHINE_swi-virt = "qemux86"
KBRANCH_swi-virt = "standard/common-pc/base"

KERNEL_FEATURES_append_swi-virt = " cfg/sound.scc cfg/paravirt_kvm.scc"

# Use latest commits from KBRANCH & KMETA
SRCREV_machine_swi-mdm9x15 = "${AUTOREV}"
SRCREV_meta_swi-mdm9x15 = "${AUTOREV}"
