SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS_${PN} += "libgcov-dev"
RDEPENDS_${PN} += "libcap-dev"
RDEPENDS_${PN} += "procps-dev"

