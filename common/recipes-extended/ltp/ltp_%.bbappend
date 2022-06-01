inherit tar-runtime


FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-SWI-ltp-cmdlib_sh.patch \
            "
