DEPENDS += "cwetool-native"

generate_cwe_pid() {
    PID=$1
    PAGE_SIZE=$2
    OUTPUT=$3
    BOOT_IMAGE=$4
    KERNEL_IMAGE=$5
    ROOTFS_IMAGE=$6
    LEGATO_IMAGE=$7
    USER1_IMAGE=$8

    unset KERNEL_IMG
    unset KERNEL_OPT
    unset KERNEL_V_FILE
    unset KERNEL_V_OPT

    unset ROOTFS_IMG
    unset ROOTFS_OPT
    unset ROOTFS_V_FILE
    unset ROOTFS_V_OPT

    unset LK_IMG
    unset LK_OPT
    unset LK_V_FILE
    unset LK_V_OPT

    unset LEGATO_IMG
    unset LEGATO_OPT
    unset LEGATO_V_OPT
    unset LEGATO_V_FILE

    unset USER1_IMG
    unset USER1_OPT

    if [ "$BOOT_IMAGE" = "true" ]; then
        LK_IMG=$(readlink -f ${DEPLOY_DIR_IMAGE}/appsboot.mbn)

        echo "Bootloader: $LK_IMG"
        LK_OPT="-fbt"

        LK_V_FILE=$(readlink -f ${DEPLOY_DIR_IMAGE}/lk.version)
        if [ -e "$LK_V_FILE" ]; then
            echo "Bootloader version: $(cat $LK_V_FILE)"
            LK_V_OPT="-vfbt"
        else
            unset LK_V_FILE
        fi
    fi

    if [ "$KERNEL_IMAGE" = "true" ]; then
        KERNEL_IMG="${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x15.${PAGE_SIZE}.img"

        echo "Kernel: $KERNEL_IMG"
        KERNEL_OPT="-kernel"

        KERNEL_V_FILE=$(readlink -f ${DEPLOY_DIR_IMAGE}/kernel.version)
        if [ -e "$KERNEL_V_FILE" ]; then
            echo "Kernel version: $(cat $KERNEL_V_FILE)"
            KERNEL_V_OPT="-vkernel"
        else
            unset KERNEL_V_FILE
        fi
    fi

    if [ "$ROOTFS_IMAGE" = "true" ]; then
        ROOTFS_IMG="${DEPLOY_DIR_IMAGE}/mdm9x15-image-${IMAGE_TYPE}-swi-mdm9x15.${PAGE_SIZE}.default"
        if ! [ -e "$ROOTFS_IMG" ]; then
            ROOTFS_IMG="${DEPLOY_DIR_IMAGE}/mdm9x15-image-${IMAGE_TYPE}-swi-mdm9x15.${PAGE_SIZE}.ubi"
        fi

        echo "Rootfs: $ROOTFS_IMG"
        ROOTFS_OPT="-rfs"

        ROOTFS_V_FILE=$(readlink -f ${DEPLOY_DIR_IMAGE}/rootfs.version)
        if [ -e "$ROOTFS_V_FILE" ]; then
            echo "Rootfs version: $(cat $ROOTFS_V_FILE)"
            ROOTFS_V_OPT="-vrfs"
        else
            unset ROOTFS_V_FILE
        fi
    fi

    if [ "$LEGATO_IMAGE" = "true" ]; then
        LEGATO_IMG=$(readlink -f ${DEPLOY_DIR_IMAGE}/legato-image.${TARGET}.default)
        if ! [ -e "$LEGATO_IMG" ]; then
            exit 1
        fi

        echo "Legato: $LEGATO_IMG"
        LEGATO_OPT="-ufs"

        LEGATO_V_FILE=$(readlink -f ${DEPLOY_DIR_IMAGE}/legato-image.version)
        if [ -e "$LEGATO_V_FILE" ]; then
            echo "Legato version: $(cat $LEGATO_V_FILE)"
            LEGATO_V_OPT="-vufs"
        else
            unset LEGATO_V_FILE
        fi
    fi

    if [ "$USER1_IMAGE" = "true" ]; then
        # Set the location of USER1 partition image. Also indicate to CWE tool
        # that image "belongs" to USER1 partition.
        USER1_IMG="${DEPLOY_DIR_IMAGE}/mdm9x15-image-${IMAGE_TYPE}-swi-mdm9x15-user1.${PAGE_SIZE}.ubi"
        USER1_OPT="-uapp"
    fi

    yoctocwetool.sh \
        -pid $PID \
        -z \
        -o $OUTPUT \
        $LK_OPT $LK_IMG \
        $LK_V_OPT $LK_V_FILE \
        $KERNEL_OPT $KERNEL_IMG \
        $KERNEL_V_OPT $KERNEL_V_FILE \
        $ROOTFS_OPT $ROOTFS_IMG \
        $ROOTFS_V_OPT $ROOTFS_V_FILE \
        $LEGATO_OPT $LEGATO_IMG \
        $LEGATO_V_OPT $LEGATO_V_FILE \
        $USER1_OPT $USER1_IMG

}

generate_cwe_target() {
    TARGET=$1

    PAGE_SIZE=4k

    case $TARGET in
        ar7)    PID='A911' ;;
        ar86)   PID='A911' ;;
        wp7)    PID='9X15' ;;
        wp85)   PID='Y912'
                PAGE_SIZE=2k ;;
        *)
            echo "Unknown product '$TARGET'"
            exit 1
        ;;
    esac

    if [ "${IMAGE_TYPE}" != "minimal" ]; then
        # The cwe name must be different for other types of images (testperf...)
        CWE_NAME_EXTRA=_${IMAGE_TYPE}
    fi

    echo "Generating CWE package for $TARGET (just lk)"
    generate_cwe_pid $PID $PAGE_SIZE \
            ${DEPLOY_DIR_IMAGE}/boot${CWE_NAME_EXTRA}_$TARGET.cwe \
            true false false false false

    echo "Generating CWE package for $TARGET ($PAGE_SIZE)"
    generate_cwe_pid $PID $PAGE_SIZE \
            ${DEPLOY_DIR_IMAGE}/yocto${CWE_NAME_EXTRA}_$TARGET.cwe \
            false true true false false

    echo "Generating CWE package for $TARGET ($PAGE_SIZE, with lk)"
    generate_cwe_pid $PID $PAGE_SIZE \
            ${DEPLOY_DIR_IMAGE}/boot-yocto${CWE_NAME_EXTRA}_$TARGET.cwe \
            true true true false false

    if [ "${LEGATO_BUILD}" = "true" ]; then
        echo "Generating CWE package for $TARGET ($PAGE_SIZE)"
        generate_cwe_pid $PID $PAGE_SIZE \
                ${DEPLOY_DIR_IMAGE}/yocto-legato${CWE_NAME_EXTRA}_$TARGET.cwe \
                false true true true false

        echo "Generating CWE package for $TARGET ($PAGE_SIZE, with lk, with Legato)"
        generate_cwe_pid $PID $PAGE_SIZE \
            ${DEPLOY_DIR_IMAGE}/boot-yocto-legato${CWE_NAME_EXTRA}_$TARGET.cwe \
            true true true true false
    fi

    # Special CWE image for USER1 partition only.
    echo "Generating CWE package for $TARGET (just USER1 partition)"
    generate_cwe_pid $PID $PAGE_SIZE \
            ${DEPLOY_DIR_IMAGE}/user1${CWE_NAME_EXTRA}-single-part-ubifs-empty_$TARGET.cwe \
            false false false false true

}

# Only depend on legato-image if this is a LEGATO_BUILD
def check_legato_dep(d):
    legato_build = d.getVar('LEGATO_BUILD', True) or "false"
    if legato_build == "true":
        return "legato-image:do_install"
    return ""

# DM: There is no USER1 dependency, because USER1 UBI container is generated in
# the thread generating other UBI containers, including rootfs .
do_generate_cwe[depends]  = "${@check_legato_dep(d)}"
do_generate_cwe[depends] += "cwetool-native:do_populate_sysroot"
do_generate_cwe[depends] += "${PN}:do_install"
do_generate_cwe[depends] += "${PN}:do_image_complete"
do_generate_cwe[depends] += "virtual/kernel:do_build"

do_generate_cwe() {
    for target in ${LEGATO_ROOTFS_TARGETS}; do
        generate_cwe_target $target
    done
}

addtask generate_cwe before do_build

