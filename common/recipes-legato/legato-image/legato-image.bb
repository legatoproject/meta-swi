DESCRIPTION = "Sierra Wireless Legato Image"
HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

DEPENDS += "yaffs2-utils"

inherit legato

INHIBIT_DEFAULT_DEPS = "1"

compile_target() {
    PAGE_SIZE=4096

    if [[ "$LEGATO_TARGET" == "wp85" ]]; then
        PAGE_SIZE=2048
    fi

    # Generate the framework image
    mkyaffs2image -c $PAGE_SIZE -s 160 "${LEGATO_STAGING_DIR}/$LEGATO_TARGET" "${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.yaffs2"
}

do_compile[deptask] = "do_install_image"

do_configure[noexec] = "1"
do_install[noexec] = "1"

# To add legato applications to the image, add them as dependencies using legato-image.bbappend files
#DEPENDS += "legato-modemdemo"
