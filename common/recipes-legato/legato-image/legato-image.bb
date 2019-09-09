DESCRIPTION = "Legato Image"
HOMEPAGE = "http://www.legato.io/"
LICENSE = "MPL-2.0"

DEPENDS += "squashfs-tools-native"
DEPENDS += "mtd-utils-native"

inherit legato
inherit ubi-image
inherit android-signing

gen_version() {
    version_file="${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$LEGATO_TARGET/system/version"
    echo $version_file
    if ! [ -e "$version_file" ]; then
        version_file="${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$LEGATO_TARGET/opt/legato/version"
    fi

    export VERSION="$(cat $version_file) $(hostname) $(date +'%Y/%m/%d %H:%M:%S')"

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

    mkdir -p ${DEPLOY_DIR_IMAGE}

    gen_version

    rm -rf $IMG_DIR
    mkdir -p $IMG_DIR
    mklegatoimg -t $LEGATO_TARGET -d "${LEGATO_STAGING_DIR}/$LEGATO_VERSION/$LEGATO_TARGET" -o $IMG_DIR -v $VERSION

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

    # sign the image with single cert
    cp rhash.bin rhash-unsigned.bin
    android_signature_add /legato rhash-unsigned.bin rhash.bin media

    # ubi
    create_ubi_image '4k' legatoimg/ubi/ubinize.cfg legato-signed.ubi legato-signed-link.ubi

    # cwe
    hdrcnv legato-signed.ubi -OH user.hdr -IT USER -PT 9X28 -V "Legato" -B 00000001
    cat user.hdr legato-signed.ubi > legato-signed.user

    hdrcnv legato-signed.user -OH appl.hdr -IT APPL -PT 9X28 -V "Legato" -B 00000001
    cat appl.hdr legato-signed.user > legato-signed.cwe
    cp legato-signed.cwe ${DEPLOY_DIR_IMAGE}/legato-image-signed.$LEGATO_TARGET.cwe
}

compile_target() {
    if [ -z "${LEGATO_VERSION}" ]; then
        get_legato_version
    fi

    generate_images_mklegatoimg
}

do_compile[deptask] = "do_install_image"

do_configure[noexec] = "1"
do_install[noexec] = "1"

