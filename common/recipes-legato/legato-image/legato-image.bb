DESCRIPTION = "Sierra Wireless Legato Image"
HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

DEPENDS += "yaffs2-utils"
DEPENDS += "squashfs-tools"
DEPENDS += "mtd-utils"

inherit legato
inherit ubi-image

INHIBIT_DEFAULT_DEPS = "1"

SRC_URI += "file://ubinize-legato.cfg"

generate_image_yaffs2() {
    yaffs2_opts="-c 4096 -s 160"

    if [[ "$LEGATO_TARGET" == "wp85" ]]; then
        yaffs2_opts=""
    fi

    # Generate the framework image
    mkyaffs2image $yaffs2_opts "${LEGATO_STAGING_DIR}/$LEGATO_TARGET" "${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.yaffs2"
}

generate_image_squashfs() {

    # Generate the framework image
    mksquashfs "${LEGATO_STAGING_DIR}/$LEGATO_TARGET" "${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.squashfs" -noappend
}

generate_image_ubi() {
    page_size=4k

    if [[ "$LEGATO_TARGET" == "wp85" ]]; then
        page_size=2k
    fi

    local image_path="${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.squashfs"
    local ubi_path="${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.ubi"

    create_ubi_image $page_size ${WORKDIR}/ubinize-legato.cfg $image_path $ubi_path
}

compile_target() {
    generate_image_yaffs2
    generate_image_squashfs
    generate_image_ubi

    # Default to ubi
    ln -sf "${PN}.$LEGATO_TARGET.ubi" "${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.default"
}

do_compile[deptask] = "do_install_image"

do_configure[noexec] = "1"
do_install[noexec] = "1"

# To add legato applications to the image, add them as dependencies using legato-image.bbappend files
#DEPENDS += "legato-modemdemo"

