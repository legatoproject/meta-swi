FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://file_read_only_open.patch"

SRC_URI_append_class-native = " file://Retry-device_open-without-direct-io.patch"
