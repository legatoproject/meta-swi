FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI_append += " file://0001-swi-qualcomm-handlepowerkey-ingore.patch"
SRC_URI_append += " file://0001-setup-start-stop-one-unit-the-longest-time.patch"
