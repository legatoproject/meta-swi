SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS_${PN} += "libgcov-dev"
RDEPENDS_${PN} += "libcap-dev"
RDEPENDS_${PN} += "procps-dev"
RDEPENDS_${PN} += "kernel-dev"
RDEPENDS_${PN} += "curl-dev"
RDEPENDS_${PN} += "tinycbor-dev"
RDEPENDS_${PN} += "gdbserver"
