SUMMARY = "Sierra Software Image common content"
LICENSE = "MIT"
PR = "r0"

# Set target for package group
PACKAGE_ARCH = "${MACHINE_ARCH}"

inherit packagegroup

RDEPENDS:${PN} += "shadow"
RDEPENDS:${PN} += "dnsmasq"
RDEPENDS:${PN} += "bridge-utils"
RDEPENDS:${PN} += "pimd"
RDEPENDS:${PN} += "procps"
RDEPENDS:${PN} += "mtd-utils"
RDEPENDS:${PN} += "mtd-utils-ubifs"
RDEPENDS:${PN} += "libopencore-amr"
RDEPENDS:${PN} += "libvo-amrwbenc"

RDEPENDS:${PN} += "conntrack-tools"

# Required to provide some extended privileges
# to non-root processes
RDEPENDS:${PN} += "libcap"
RDEPENDS:${PN} += "libcap-bin"

# Add curl with https support
RDEPENDS:${PN} += "curl"
RDEPENDS:${PN} += "ca-certificates"

# Required for extended file attributes
RDEPENDS:${PN} += "attr"

# Adds an alternative to tar (bsdtar)
RDEPENDS:${PN} += "bsdtar"

# Provide base support for Legato
RDEPENDS:${PN} += "legato-init"

# Add some extra packages for tool integration
RDEPENDS:${PN} += "dropbear"

RDEPENDS:${PN} += "iproute2"
RDEPENDS:${PN} += "iproute2-tc"
RDEPENDS:${PN} += "iptables"

RDEPENDS:${PN} += "openssl"
RDEPENDS:${PN} += "ppp"

# Add rngd for entropy
RDEPENDS:${PN} += "rng-tools"

# Make sure to package libgcc in the rootfs
# since Legato depends on it
RDEPENDS:${PN} += "libgcc"
RDEPENDS:${PN} += "libstdc++"

# IMA/EVM support tools
RDEPENDS:${PN} += "ima-evm-utils"
RDEPENDS:${PN} += "keyutils"

# Transparently update ld cache.
RDEPENDS:${PN} += "update-ld-cache"

# Needed for differential update (bsdiff and bspatch)
RDEPENDS:${PN} += "bsdiff"

# Add ntpdate from ntp package
RDEPENDS:${PN} += "ntpdate"
