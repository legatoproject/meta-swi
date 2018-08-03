# This recipe exists for the sake of inducing the generation of
# the Makefile in the ${STAGING_KERNEL_BUILDDIR} which Legato
# needs in order to do its kernel module build.

# There is no kernel C code here; do not look for it! This is never built
# as a package nor included in the image; legato-af.bb just has a dependency on
# the do_compile task of this recipe for the sake of obtaining its side effect
# of dropping the needed Makefile.

DESCRIPTION = "dummy kernel module recipe"
LICENSE = "CC0-1.0"
LIC_FILES_CHKSUM = "file://Makefile;beginline=1;endline=1;md5=c3d98ec9a8ca210447b319a94b2cb325"

inherit module

PR = "r0"
PV = "0.1"

SRC_URI = "file://Makefile"

S = "${WORKDIR}"

do_make_scripts_prepend() {
    export STAGING_LIBDIR_NATIVE="${STAGING_LIBDIR_NATIVE}" STAGING_INCDIR_NATIVE="${STAGING_INCDIR_NATIVE}"
}

do_install() {
}
