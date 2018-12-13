SUMMARY = "Sierra Software Image common content"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS_${PN} += "perl"
RDEPENDS_${PN} += "iperf3"
RDEPENDS_${PN} += "tcpdump"
RDEPENDS_${PN} += "strace"
RDEPENDS_${PN} += "usbutils"
RDEPENDS_${PN} += "opkg"
RDEPENDS_${PN} += "openssh-sftp-server"
RDEPENDS_${PN} += "tcf-agent"

RDEPENDS_${PN} += "lttng-ust"
# RDEPENDS_${PN} += "lttng-modules"
RDEPENDS_${PN} += "lrzsz"
RDEPENDS_${PN} += "net-tools"
