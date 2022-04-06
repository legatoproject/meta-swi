SUMMARY = "Sierra Software Image common content"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS:${PN} += "perl"
RDEPENDS:${PN} += "iperf3"
RDEPENDS:${PN} += "tcpdump"
RDEPENDS:${PN} += "strace"
RDEPENDS:${PN} += "usbutils"
RDEPENDS:${PN} += "opkg"
RDEPENDS:${PN} += "openssh-sftp-server"
RDEPENDS:${PN} += "tcf-agent"
RDEPENDS:${PN} += "systemtap"

RDEPENDS:${PN} += "lttng-ust"
# RDEPENDS:${PN} += "lttng-modules"
RDEPENDS:${PN} += "lrzsz"
RDEPENDS:${PN} += "net-tools"
