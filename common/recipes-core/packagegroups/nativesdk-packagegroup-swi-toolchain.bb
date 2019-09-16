SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup nativesdk

PACKAGEGROUP_DISABLE_COMPLEMENTARY = "1"

RDEPENDS_${PN} += "squashfs-tools"
RDEPENDS_${PN} += "mtd-utils"
RDEPENDS_${PN} += "mtd-utils-ubifs"
RDEPENDS_${PN} += "attr"
RDEPENDS_${PN} += "cryptsetup"
RDEPENDS_${PN} += "qemu"
RDEPENDS_${PN} += "ima-evm-utils"
RDEPENDS_${PN} += "keyutils"
RDEPENDS_${PN} += "libarchive"
RDEPENDS_${PN} += "fakeroot"
RDEPENDS_${PN} += "ima-support-tools"
RDEPENDS_${PN} += "cwetool"
RDEPENDS_${PN} += "bsdiff"
RDEPENDS_${PN} += "glib-2.0-codegen"
