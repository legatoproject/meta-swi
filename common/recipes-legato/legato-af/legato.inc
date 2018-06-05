HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL-2.0"
LIC_FILES_CHKSUM = "file://${LEGATO_WORKDIR}/LICENSE.md;md5=55a288862ec4d1fd20f996344d511a1f"

DEPENDS += "cmake-native"
DEPENDS += "ninja-native"

# This adds files from the LEGATO_WORKDIR to SRC_URI, which allows bitbake to track
# the checksum of this files and therefore rebuild when they change.
# Generated files are excluded from the list.
def list_legato_files(d):
    try:
        from urllib.parse import quote
    except ImportError:
        from urllib import quote

    startpath = d.getVar("LEGATO_WORKDIR", True)
    if not startpath:
        return ""

    file_list = []

    if not startpath.endswith("/"):
        startpath += "/"

    for root, dirs, files in os.walk(startpath):
        path = root.replace(startpath, '')
        if path.startswith("build"):
            continue
        if path.startswith("releases"):
            continue
        if path.startswith("bin"):
            continue
        if ".git" in path:
            continue

        for f in files:
            if f.endswith(".pyc"):
                continue
            if " " in f:
                continue # Unable to handle files that contain a space

            file_list.append( "file://" + quote(os.path.join(startpath, path, f)) )

    return "\n".join(file_list)

SRC_URI = "${@list_legato_files(d)}"

S="${WORKDIR}/${PN}"
B="${S}"

# Explicitly bypass fetch
# Legato should have already been fetched and be present in ${LEGATO_WORKDIR}.
# If the working directory does not exist, then there is a problem.
do_fetch () {
    if ! [ -e "${LEGATO_WORKDIR}" ]; then
        echo "Legato Working Directory (LEGATO_WORKDIR = ${LEGATO_WORKDIR}) does not exist"
        exit 1
    fi
}

# Override unpack for this recipe.
do_unpack() {
    rm -rf ${WORKDIR}/${PN}
    mkdir -p ${WORKDIR}/${PN}

    # Copy all files
    tar cf - -C ${LEGATO_WORKDIR} . | tar xpf - -C ${WORKDIR}/${PN}

    # Fix git repositories
    cd ${LEGATO_WORKDIR}
    find -name "*.git" > ${WORKDIR}/list-git
    cd ${WORKDIR}/${PN}
    for dir in $(cat ${WORKDIR}/list-git); do
        rm -rf $dir
        ln -sf ${LEGATO_WORKDIR}/$dir $dir
    done

    # Clean in case LEGATO_WORKDIR has been used by itself
    make clean
}

PRIVATE_LIBS = "libjansson.so.4"

do_compile_prepend() {
    export LEGATO_ROOT="${S}"
    export PATH="${S}/bin:$PATH"
}
