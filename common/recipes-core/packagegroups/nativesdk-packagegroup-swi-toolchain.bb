SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r1"

# Set target for package group
PACKAGE_ARCH = "${SDK_ARCH}-${SDKPKGSUFFIX}"

inherit packagegroup nativesdk

PACKAGEGROUP_DISABLE_COMPLEMENTARY = "1"

RDEPENDS:${PN} += "squashfs-tools"
RDEPENDS:${PN} += "mtd-utils"
RDEPENDS:${PN} += "mtd-utils-ubifs"
RDEPENDS:${PN} += "attr"
RDEPENDS:${PN} += "cryptsetup"
RDEPENDS:${PN} += "qemu"
RDEPENDS:${PN} += "ima-evm-utils"
RDEPENDS:${PN} += "keyutils"
RDEPENDS:${PN} += "libarchive"
RDEPENDS:${PN} += "fakeroot"
RDEPENDS:${PN} += "ima-support-tools"
RDEPENDS:${PN} += "cwetool"
RDEPENDS:${PN} += "bsdiff"
RDEPENDS:${PN} += "glib-2.0-codegen"
