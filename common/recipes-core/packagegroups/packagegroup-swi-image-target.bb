SUMMARY = "Sierra Software Image common content"
LICENSE = "MIT"
PR = "r0"

inherit packagegroup

RDEPENDS_${PN} += "shadow"
RDEPENDS_${PN} += "dnsmasq"
RDEPENDS_${PN} += "bridge-utils"
RDEPENDS_${PN} += "pimd"
RDEPENDS_${PN} += "procps"
RDEPENDS_${PN} += "mtd-utils"
RDEPENDS_${PN} += "mtd-utils-ubifs"
RDEPENDS_${PN} += "libopencore-amr"
RDEPENDS_${PN} += "iperf"
RDEPENDS_${PN} += "libvo-amrwbenc"
RDEPENDS_${PN} += "tcpdump"

RDEPENDS_${PN} += "conntrack-tools"

# Required to provide some extended privileges
# to non-root processes
RDEPENDS_${PN} += "libcap"
RDEPENDS_${PN} += "libcap-bin"

# Userland quota support.
RDEPENDS_${PN} += "quota"

# Add curl with https support
RDEPENDS_${PN} += "curl"
RDEPENDS_${PN} += "ca-certificates"

# Required for extended file attributes
RDEPENDS_${PN} += "attr"

# Adds an alternative to tar (bsdtar)
RDEPENDS_${PN} += "libarchive"
RDEPENDS_${PN} += "libarchive-bin"

# Enable (de)compression with bz2
RDEPENDS_${PN} += "bzip2"

# Provide base support for Legato
RDEPENDS_${PN} += "legato-init"

# Add some extra packages for tool integration
RDEPENDS_${PN} += "dropbear"
RDEPENDS_${PN} += "strace"
RDEPENDS_${PN} += "python-core"

RDEPENDS_${PN} += "iproute2"
RDEPENDS_${PN} += "iproute2-tc"
RDEPENDS_${PN} += "iptables"

RDEPENDS_${PN} += "opkg"
RDEPENDS_${PN} += "openssl"
RDEPENDS_${PN} += "ppp"

# Required for some Developer Studio features.
# Not needed for production builds
RDEPENDS_${PN} += "openssh-sftp-server"
RDEPENDS_${PN} += "tcf-agent"

# Add usb utils to enable lsusb on the target
RDEPENDS_${PN} += "usbutils"

# Add rngd for entropy
RDEPENDS_${PN} += "rng-tools"

# Add tinucbor to all targets
RDEPENDS_${PN} += "tinycbor"
