SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS:${PN} += "libcap-dev"
RDEPENDS:${PN} += "procps-dev"
# Workaround issue that nothing provides /usr/bin/awk needed by kernel-dev
RDEPENDS:${PN} += "gawk"
RDEPENDS:${PN} += "kernel-dev"
RDEPENDS:${PN} += "curl-dev"

# For Legato devMode
RDEPENDS:${PN} += "gdbserver"
RDEPENDS:${PN} += "strace"
RDEPENDS:${PN} += "tcf-agent"
RDEPENDS:${PN} += "openssh-sftp-server"
RDEPENDS:${PN} += "usbutils"
RDEPENDS:${PN} += "iperf3"
RDEPENDS:${PN} += "tcpdump"
RDEPENDS:${PN} += "lsof"
