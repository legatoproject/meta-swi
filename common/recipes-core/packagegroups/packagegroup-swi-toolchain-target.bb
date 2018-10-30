SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS_${PN} += "libcap-dev"
RDEPENDS_${PN} += "procps-dev"
# Workaround issue that nothing provides /usr/bin/awk needed by kernel-dev
RDEPENDS_${PN} += "gawk"
RDEPENDS_${PN} += "kernel-dev"
RDEPENDS_${PN} += "curl-dev"

# For Legato devMode
RDEPENDS_${PN} += "gdbserver"
RDEPENDS_${PN} += "strace"
RDEPENDS_${PN} += "tcf-agent"
RDEPENDS_${PN} += "openssh-sftp-server"
RDEPENDS_${PN} += "usbutils"
RDEPENDS_${PN} += "iperf3"
RDEPENDS_${PN} += "tcpdump"
RDEPENDS_${PN} += "lsof"
