FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://smack.cfg"
SRC_URI += "file://pm.cfg"

# x86
COMPATIBLE_MACHINE_swi-virt-x86 = "swi-virt-x86"

KMACHINE_swi-virt-x86 = "qemux86"
KBRANCH_swi-virt-x86 = "${KBRANCH_qemux86}"

KERNEL_FEATURES_append_swi-virt-x86 = "${KERNEL_FEATURES_append_qemux86}"

SRCREV_machine_swi-virt-x86 = "${SRCREV_machine_qemux86}"

# arm
COMPATIBLE_MACHINE_swi-virt-arm = "swi-virt-arm"

KMACHINE_swi-virt-arm = "qemuarm"
KBRANCH_swi-virt-arm = "${KBRANCH_qemuarm}"

SRCREV_machine_swi-virt-arm = "${SRCREV_machine_qemuarm}"
