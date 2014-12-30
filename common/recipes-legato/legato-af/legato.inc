HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

DEPENDS += "cmake-native"

# Default is to pull from github, Can be overridden in the build script
LEGATO_REPO ?= "git://github.com/legatoproject/legato-af.git;protocol=https;rev=master"
LEGATO_CHKSUM ?= "4e5d47c0504d0c2f7a032a6078d32a93cd8f583eee135ca4f6eeb00215c50563"

# Need to override this in the build if you are not using a git-based
# version. If it is an http download you will need to adjust this value to match
LEGATO_WRKDIR ?= "${WORKDIR}/git"

SRC_URI = "${LEGATO_REPO}"
SRC_URI[sha256sum] ?= "${LEGATO_CHKSUM}"

# Don't specify this here if you are using it in the git URL
# from the build script
#SRCREV_pn-${PN} = "${AUTOREV}"

S = "${LEGATO_WRKDIR}"

