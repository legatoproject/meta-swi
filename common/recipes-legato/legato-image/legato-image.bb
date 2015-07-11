DESCRIPTION = "Sierra Wireless Legato Image"
HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL2.0"

DEPENDS += "yaffs2-utils"
DEPENDS += "squashfs-tools"
DEPENDS += "mtd-utils"

inherit legato

INHIBIT_DEFAULT_DEPS = "1"

gen_version() {
    export VERSION="$(cat ${LEGATO_STAGING_DIR}/$LEGATO_TARGET/opt/legato/version) $(hostname) $(date +'%Y/%m/%d %H:%M:%S')"

    echo $VERSION > ${DEPLOY_DIR_IMAGE}/${PN}.version
}

copy_image() {
    IMG_FULLNAME=$(basename $file)
    IMG_NAME="${IMG_FULLNAME%.*}"
    IMG_EXT="${IMG_FULLNAME##*.}"

    DST_NAME="${PN}.$LEGATO_TARGET.$IMG_EXT"

    echo "Copying $file to $DST_NAME"
    cp $file ${DEPLOY_DIR_IMAGE}/$DST_NAME
}

generate_images_mklegatoimg() {
    IMG_DIR="${WORKDIR}/images-${LEGATO_TARGET}"

    gen_version

    rm -rf $IMG_DIR
    mkdir -p $IMG_DIR
    mklegatoimg -t $LEGATO_TARGET -d "${LEGATO_STAGING_DIR}/$LEGATO_TARGET" -o $IMG_DIR -v $VERSION

    # Copy
    cd $IMG_DIR
    for file in $(ls -1 | grep -v cwe); do
        if [ -f "$file" ]; then
            copy_image $file
        fi
    done

    for file in $(ls -1 | grep -e "legato[z]*.cwe"); do
        copy_image $file
    done
}

generate_image_yaffs2() {
    yaffs2_opts="-c 4096 -s 160"

    if [[ "$LEGATO_TARGET" == "wp85" ]]; then
        yaffs2_opts=""
    fi

    # Generate the framework image
    mkyaffs2image $yaffs2_opts "${LEGATO_STAGING_DIR}/$LEGATO_TARGET" "${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.yaffs2"
}

compile_target() {
    # Check if legato version is recent enough to use mklegatoimg
    if grep BASH_SOURCE $(which mklegatoimg); then
        generate_images_mklegatoimg
    else
        generate_image_yaffs2
        ln -sf "${PN}.$LEGATO_TARGET.yaffs2" "${DEPLOY_DIR_IMAGE}/${PN}.$LEGATO_TARGET.default"
    fi
}

do_compile[deptask] = "do_install_image"

do_configure[noexec] = "1"
do_install[noexec] = "1"

# To add legato applications to the image, add them as dependencies using legato-image.bbappend files
#DEPENDS += "legato-modemdemo"

