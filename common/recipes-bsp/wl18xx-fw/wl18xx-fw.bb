DESCRIPTION = "Firmware files for use with TI wl18xx"
LICENSE = "TI-TSPA"
LIC_FILES_CHKSUM = "file://LICENCE;md5=4977a0fe767ee17765ae63c435a32a9e"

SRC_URI = " \
	git://git.ti.com/wilink8-wlan/wl18xx_fw.git;protocol=git;branch=${BRANCH} \
	file://0001-Add-Makefile-to-install-firmware-files.patch \
"

# Choose a git version aligned to the kernel version.
def version_git(d):
    kernel_provider = d.getVar("PREFERRED_PROVIDER_virtual/kernel", True)
    kernel_version = d.getVar('PREFERRED_VERSION_%s' % kernel_provider, True)
    if kernel_version == "4.14%":
        # Tag: R8.7-SP3 (8.7.3)
        return "f659be25473e4bde8dc790bff703ecacde6e21da"
    else:
        # Tag: ol_r8.a9.17
        return "2568d8f61fd509eabb112110c20ea31c088ef6b9"

SRCREV = '${@version_git(d)}'

BRANCH = "master"

S = "${WORKDIR}/git"

CLEANBROKEN = "1"

do_compile() {
    :
}

do_install() {
    oe_runmake 'DEST_DIR=${D}' install
}

FILES:${PN} = "/lib/firmware/ti-connectivity/*"
