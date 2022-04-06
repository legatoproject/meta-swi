inherit tar-runtime


FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-SWI-ltp-cmdlib_sh.patch \
            file://0003-SWI-runltp-tmp-for-dd.patch \
            "
