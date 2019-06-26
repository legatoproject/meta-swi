inherit autotools-brokensep

DESCRIPTION = "Safe integer operation library for C"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

# Tag LE.UM.3.3.2-01400-SDX55
SRCREV = "aa0725fb1da35e47676b6da30009322eb5ed59be"
SAFEIOP_REPO = "git://codeaurora.org/platform/external/safe-iop;branch=le-blast.lnx.1.2"

PR = "r0"

FILESPATH =+ "${WORKSPACE}:"

SRC_URI   = "${SAFEIOP_REPO}"
SRC_URI  += "file://autotools.patch"

S = "${WORKDIR}/git"
