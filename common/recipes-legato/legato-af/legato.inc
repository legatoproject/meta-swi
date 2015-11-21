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

LEGATO_WORKDIR ?= "${@determine_legato_workdir(d)}"

SRC_URI = "${LEGATO_REPO}"
S = "${LEGATO_WORKDIR}"

do_generate_version() {
    make version

    # Remove phony from 'build_version' or 'version' targets to make sure
    # that the version will not change
    sed -i 's/.PHONY: version//g' ${S}/Makefile
    sed -i 's/.PHONY: build_version//g' ${S}/Makefile
}

addtask generate_version before do_compile after do_unpack

do_compile_prepend() {
    # If there is some unexpected pending changes, regenerate version file
    if git status -s | grep -ve '\(Makefile\|proprietary.*\|tools\)'; then
        do_generate_version
    fi

    export LEGATO_ROOT="${S}"
    export PATH="${S}/bin:$PATH"
}

