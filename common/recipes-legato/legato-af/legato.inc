HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

DEPENDS += "cmake-native"

# Default is to pull from github, Can be overridden in the build script
LEGATO_REPO ?= "git://github.com/legatoproject/legato-af.git;protocol=https;rev=master"

# Disable checksum checking
python () {
    d.setVar("BB_STRICT_CHECKSUM", False)
}

# Determine legato working directory based on origin
def determine_legato_workdir(d):
    legatoRepo = d.getVar("LEGATO_REPO", True)

    # Release tarball ?
    import re
    nameMatch = re.match(r'.*\/(legato-.*)\.tar.*', legatoRepo)
    if nameMatch:
        return d.getVar("WORKDIR", True) + "/" + nameMatch.group(1)
    return d.getVar("WORKDIR", True) + "/git"

LEGATO_WRKDIR ?= "${@determine_legato_workdir(d)}"

SRC_URI = "${LEGATO_REPO}"
S = "${LEGATO_WRKDIR}"

