HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

LEGATO_REPO ?= "git://github.com/legatoproject/legato-af.git;protocol=https"
LEGATO_CHKSUM ?= "4e5d47c0504d0c2f7a032a6078d32a93cd8f583eee135ca4f6eeb00215c50563"
LEGATO_WRKDIR ?= "${WORKDIR}/git"

SRC_URI = "${LEGATO_REPO}"
SRC_URI[sha256sum] ?= "${LEGATO_CHKSUM}"
SRCREV_pn-${PN} = "${AUTOREV}"

S = "${LEGATO_WRKDIR}"
