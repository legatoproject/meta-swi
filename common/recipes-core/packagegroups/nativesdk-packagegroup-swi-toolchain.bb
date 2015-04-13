SUMMARY = "Sierra Software Development Kit"
LICENSE = "MIT"
PR = "r1"

inherit packagegroup nativesdk

PACKAGEGROUP_DISABLE_COMPLEMENTARY = "1"

RDEPENDS_${PN} += "yaffs2-utils"

