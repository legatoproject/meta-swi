HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

DEPENDS += "cmake-native"

# Default is to pull from github, Can be overridden in the build script
LEGATO_REPO ?= "git://github.com/legatoproject/legato-af.git;protocol=https;rev=master"

# Disable checksum checking
python () {
    d.setVar("BB_STRICT_CHECKSUM", False)
}

# Determine legato working directory or version based on origin
def determine_legato_prop(d, prop):
    legatoRepo = d.getVar("LEGATO_REPO", True)

    version = 'git'
    if prop == 'workdir':
        workDir = d.getVar("WORKDIR", True) + "/git"

    # Release tarball ?
    import re
    tarballMatch = re.match(r'.*\/(legato-.*)\.tar.*', legatoRepo)
    if tarballMatch:
        version = tarballMatch.group(1)
        if prop == 'workdir':
            workDir = d.getVar("WORKDIR", True) + "/" + version
    else:
        repoMatch = re.match(r'.*;rev=([a-z0-9]{40}).*', legatoRepo)
        if repoMatch:
            version = 'git' + repoMatch.group(1)[:10]

    if prop == 'version':
        return version
    if prop == 'workdir':
        return workDir
    else:
        raise "Unknown property: " + prop

PV = "${@determine_legato_prop(d, 'version')}"
LEGATO_WORKDIR ?= "${@determine_legato_prop(d, 'workdir')}"

SRC_URI = "${LEGATO_REPO}"
S = "${LEGATO_WORKDIR}"

PRIVATE_LIBS = "libjansson.so.4"

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

