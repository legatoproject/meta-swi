# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://CVE-2018-0734.patch \
            file://CVE-2019-1559_1.patch \
            file://CVE-2019-1559_2.patch \
"
