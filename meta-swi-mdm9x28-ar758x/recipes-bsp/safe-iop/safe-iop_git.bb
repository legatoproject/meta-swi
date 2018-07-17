inherit autotools-brokensep

DESCRIPTION = "Safe integer operation library for C"
HOMEPAGE = "https://www.codeaurora.org/cgit/quic/la/platform/external/safe-iop/"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

# Tag LE.UM.1.2-15100-9x07
SRCREV = "aa0725fb1da35e47676b6da30009322eb5ed59be"
SYSTEMCORE_REPO = "git://codeaurora.org/platform/external/safe-iop;branch=le-blast.lnx.1.1.c2-rel"

SRC_URI  = "${SYSTEMCORE_REPO}"
SRC_URI  += "file://autotools.patch"

S = "${WORKDIR}/git"

PR = "r0"
