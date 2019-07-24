DEPENDS += "cwetool-native"

generate_cwe_pid() {
    PID=$1
    PLATFORM=$2
    PAGE_SIZE=$3
    OUTPUT=$4
    EDK2_IMAGE=$5
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

    unset EDK2_IMG
    unset EDK2_OPT
    unset EDK2_V_FILE
    unset EDK2_V_OPT

    unset LEGATO_IMG
    unset LEGATO_OPT
    unset LEGATO_V_OPT
    unset LEGATO_V_FILE

    if [ "$EDK2_IMAGE" = "true" ]; then
        EDK2_IMG=$(readlink -f ${DEPLOY_DIR_IMAGE}/abl.elf)

        echo "EDK2: $EDK2_IMG"
        EDK2_OPT="-fbt"
    fi

    if [ -n "$EDK2_IMG" ]; then
        EDK2_V_FILE=$(readlink -f ${DEPLOY_DIR_IMAGE}/abl.version)
        if [ -e "$EDK2_V_FILE" ]; then
            echo "EDK2 version: $(cat $EDK2_V_FILE)"
            EDK2_V_OPT="-vfbt"
        else
            unset EDK2_V_FILE
        fi
    fi

    if [ "$KERNEL_IMAGE" = "true" ]; then
        KERNEL_IMG="${DEPLOY_DIR_IMAGE}/boot-yocto-sdx55.${PAGE_SIZE}.img"

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
        ROOTFS_IMG="${DEPLOY_DIR_IMAGE}/mdm-image-${IMAGE_TYPE}-${MACHINE}.${PAGE_SIZE}.default"
        if ! [ -e "$ROOTFS_IMG" ]; then
            ROOTFS_IMG="${DEPLOY_DIR_IMAGE}/mdm-image-${IMAGE_TYPE}-${MACHINE}.${PAGE_SIZE}.ubi"
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

    # get production name
    PROD_NAME=em919x

    yoctocwetool.sh \
        -prod $PROD_NAME \
        -pid $PID \
        -platform $PLATFORM \
        -o $OUTPUT \
        $EDK2_OPT $EDK2_IMG \
        $EDK2_V_OPT $EDK2_V_FILE \
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
        wp76xx) PID[0]='Y921'
                PID[1]='Y922'
                PAGE_SIZE[1]=2k
                PLATFORM='9X28' ;;
        em919x) PID[0]='919x'
                PLATFORM='919x' ;;
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
        echo "Generating CWE package for $TARGET (${PAGE_SIZE[$i]})"
        generate_cwe_pid ${PID[$i]} $PLATFORM ${PAGE_SIZE[$i]} ${DEPLOY_DIR_IMAGE}/yocto${CWE_NAME_EXTRA}_$TARGET.${PAGE_SIZE[$i]}.cwe true true true false

    done
}

do_generate_cwe[depends] += "cwetool-native:do_populate_sysroot"
do_generate_cwe[depends] += "${PN}:do_install"
do_generate_cwe[depends] += "${PN}:do_image_complete"
do_generate_cwe[depends] += "virtual/kernel:do_build"

do_generate_cwe() {
    target=em919x
    generate_cwe_target $target
}

addtask generate_cwe before do_build

