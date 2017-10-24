DEPENDS += "cwetool-native"

generate_cwe_pid() {
    PID=$1
    PLATFORM=$2
    PAGE_SIZE=$3
    OUTPUT=$4
    BOOT_IMAGE=$5
    KERNEL_IMAGE=$6
    ROOTFS_IMAGE=$7
    LEGATO_IMAGE=$8

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

    if [ "$BOOT_IMAGE" = "default" ]; then
        LK_IMG=$(readlink -f ${DEPLOY_DIR_IMAGE}/appsboot.mbn)

        echo "Bootloader: $LK_IMG"
        LK_OPT="-fbt"

    elif [ "$BOOT_IMAGE" = "rw" ]; then
        LK_IMG=$(readlink -f ${DEPLOY_DIR_IMAGE}/appsboot_rw.mbn)

        echo "Bootloader: $LK_IMG"
        LK_OPT="-fbt"

    elif [ "$BOOT_IMAGE" = "rw_ima" ]; then
        LK_IMG=$(readlink -f ${DEPLOY_DIR_IMAGE}/appsboot_rw_ima.mbn)

        echo "Bootloader: $LK_IMG"
        LK_OPT="-fbt"

    fi

    if [ -n "$LK_IMG" ]; then
        LK_V_FILE=$(readlink -f ${DEPLOY_DIR_IMAGE}/lk.version)
        if [ -e "$LK_V_FILE" ]; then
            echo "Bootloader version: $(cat $LK_V_FILE)"
            LK_V_OPT="-vfbt"
        else
            unset LK_V_FILE
        fi
    fi

    if [ "$KERNEL_IMAGE" = "true" ]; then
        KERNEL_IMG="${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.${PAGE_SIZE}.img"

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
        ROOTFS_IMG="${DEPLOY_DIR_IMAGE}/mdm9x28-image-${IMAGE_TYPE}-${MACHINE}.${PAGE_SIZE}.default"
        if ! [ -e "$ROOTFS_IMG" ]; then
            ROOTFS_IMG="${DEPLOY_DIR_IMAGE}/mdm9x28-image-${IMAGE_TYPE}-${MACHINE}.${PAGE_SIZE}.ubi"
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

    # get production name
    PROD_NAME=${MACHINE}

    yoctocwetool.sh \
        -prod ${PROD_NAME#swi-*-} \
        -pid $PID \
        -platform $PLATFORM \
        -o $OUTPUT \
        $LK_OPT $LK_IMG \
        $LK_V_OPT $LK_V_FILE \
        $KERNEL_OPT $KERNEL_IMG \
        $KERNEL_V_OPT $KERNEL_V_FILE \
        $ROOTFS_OPT $ROOTFS_IMG \
        $ROOTFS_V_OPT $ROOTFS_V_FILE \
        $LEGATO_OPT $LEGATO_IMG \
        $LEGATO_V_OPT $LEGATO_V_FILE
}

generate_cwe_target() {
    TARGET=$1

    PAGE_SIZE[0]=4k
    PLATFORM='9X15'

    case $TARGET in
        ar7)    PID[0]='A911' ;;
        ar86)   PID[0]='A911' ;;
        wp7)    PID[0]='9X15' ;;
        wp85)   PID[1]='Y912'
                PAGE_SIZE[1]=2k ;;
        ar759x) PID[0]='9X40'
                PLATFORM[0]='9X40' ;;
        ar758x) PID[0]='9X28'
                PLATFORM='9X28' ;;
        wp76xx | wp77xx)
                PID[0]='Y921'
                PID[1]='Y922'
                PAGE_SIZE[1]=2k
                PLATFORM='9X28' ;;
        *)
            echo "Unknown product '$TARGET'"
            exit 1
        ;;
    esac

    if [ "${IMAGE_TYPE}" != "minimal" ]; then
        # The cwe name must be different for other types of images (testperf...)
        CWE_NAME_EXTRA=_${IMAGE_TYPE}
    fi

    for i in ${!PAGE_SIZE[@]};
    do
        echo "Generating CWE package for $TARGET (just lk)"
        generate_cwe_pid ${PID[$i]} $PLATFORM ${PAGE_SIZE[$i]} ${DEPLOY_DIR_IMAGE}/appsboot${CWE_NAME_EXTRA}_$TARGET.cwe default false false false

        echo "Generating CWE package for $TARGET (${PAGE_SIZE[$i]})"
        generate_cwe_pid ${PID[$i]} $PLATFORM ${PAGE_SIZE[$i]} ${DEPLOY_DIR_IMAGE}/yocto${CWE_NAME_EXTRA}_$TARGET.${PAGE_SIZE[$i]}.cwe false true true false
        if [ -f "${DEPLOY_DIR_IMAGE}/appsboot_rw.mbn" ] ; then
            echo "Generating CWE package for $TARGET (just lk_rw)"
            generate_cwe_pid ${PID[$i]} $PLATFORM ${PAGE_SIZE[$i]} ${DEPLOY_DIR_IMAGE}/appsboot${CWE_NAME_EXTRA}_rw_$TARGET.cwe rw false false false
        fi
        if [ -f "${DEPLOY_DIR_IMAGE}/appsboot_rw_ima.mbn" ] ; then
            echo "Generating CWE package for $TARGET (just lk_rw_ima)"
            generate_cwe_pid ${PID[$i]} $PLATFORM ${PAGE_SIZE[$i]} ${DEPLOY_DIR_IMAGE}/appsboot${CWE_NAME_EXTRA}_rw_ima_$TARGET.cwe rw_ima false false false
        fi

    done
#    echo "Generating CWE package for $TARGET ($PAGE_SIZE, with lk)"
#    generate_cwe_pid $PID $PLATFORM $PAGE_SIZE ${DEPLOY_DIR_IMAGE}/boot-yocto${CWE_NAME_EXTRA}_$TARGET.cwe true true true false

#    if [ "${LEGATO_BUILD}" = "true" ]; then
#        echo "Generating CWE package for $TARGET ($PAGE_SIZE)"
#        generate_cwe_pid $PID $PLATFORM $PAGE_SIZE ${DEPLOY_DIR_IMAGE}/yocto-legato${CWE_NAME_EXTRA}_$TARGET.cwe false true true true

#        echo "Generating CWE package for $TARGET ($PAGE_SIZE, with lk, with Legato)"
#        generate_cwe_pid $PID $PLATFORM $PAGE_SIZE ${DEPLOY_DIR_IMAGE}/boot-yocto-legato${CWE_NAME_EXTRA}_$TARGET.cwe true true true true
#    fi
}

# Only depend on legato-image if this is a LEGATO_BUILD
def check_legato_dep(d):
    legato_build = d.getVar('LEGATO_BUILD', True) or "false"
    if legato_build == "true":
        return "legato-image:do_install"
    return ""

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

