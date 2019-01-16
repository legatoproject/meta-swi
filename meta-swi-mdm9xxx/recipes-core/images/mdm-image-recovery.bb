require ../../../meta-swi-mdm9xxx/recipes-core/images/mdm9xxx-image-initramfs.inc

PACKAGE_INSTALL = "busybox mtd-utils-ubifs initscripts base-files"
PACKAGE_INSTALL += "cryptsetup libgcrypt"
DEPENDS = "linux-quic"

fakeroot do_filter_rootfs () {

    cd ${IMAGE_ROOTFS}

    if [ -f ${IMAGE_ROOTFS}/init.sh ]; then
        rm -f ${IMAGE_ROOTFS}/init.sh
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/passwd ]; then
        sed -i 's/root:x:/root::/' ${IMAGE_ROOTFS}/etc/passwd
    fi

    if [ -f ${IMAGE_ROOTFS}/etc/group ]; then
        sed -i 's/root:x:/root::/' ${IMAGE_ROOTFS}/etc/group
    fi

    # Create basic folders
    for entry in bin dev lib mnt proc run sys tmp var; do
        mkdir -p $entry
        chown 755 $entry
    done

    # Populate rootfs with some devices
    mknod dev/console c 5 1
    mknod dev/null c 1 3
    mknod dev/ttyHSL0 c 249 0
    mknod dev/ttyHSL1 c 249 1
    mknod dev/urandom c 1 9
    mknod dev/zero c 1 5
    if ! [[ -e dev/tty2 ]]; then
        mknod -m 600 dev/tty2 c 4 2
        mknod -m 600 dev/tty3 c 4 3
        mknod -m 600 dev/tty4 c 4 4
    fi
}

DEPENDS += "cwetool-native"

generate_rcy_cwe() {
    PID=$1
    PLATFORM=$2
    PAGE_SIZE=$3
    OUTPUT=$4

    unset KERNEL_IMG
    unset KERNEL_OPT

    if [ "${PLATFORM}" = "9X28" ]; then
        KERNEL_IMG="${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x28.${PAGE_SIZE}.img"
    elif [ "${PLATFORM}" = "9X40" ]; then
        KERNEL_IMG="${DEPLOY_DIR_IMAGE}/boot-yocto-mdm9x40.${PAGE_SIZE}.img"
    else
        echo "Unsupported platform '$PLATFORM'"
        exit 1
    fi

    echo "Kernel: $KERNEL_IMG"
    KERNEL_OPT="-kernel"

    yoctocwetool.sh \
        -pid $PID \
        -platform $PLATFORM \
        -o $OUTPUT \
        $KERNEL_OPT $KERNEL_IMG \
        -rcy
}

generate_rcy_cwe_target() {
    TARGET=$1

    PAGE_SIZE=4k
    PLATFORM='9X15'

    case $TARGET in
        ar7)    PID='A911' ;;
        ar86)   PID='A911' ;;
        wp7)    PID='9X15' ;;
        wp85)   PID='Y912'
                PAGE_SIZE=2k ;;
        ar758x) PID='9X28'
                PLATFORM='9X28'
                PAGE_SIZE=4k ;;
        ar759x) PID='9X40'
                PLATFORM='9X40'
                PAGE_SIZE=4k ;;
        *)
            echo "Unknown product '$TARGET'"
            exit 1
        ;;
    esac

    echo "Generating CWE package for $TARGET ($PAGE_SIZE)"
    generate_rcy_cwe $PID $PLATFORM $PAGE_SIZE ${DEPLOY_DIR_IMAGE}/kernel-rcy${CWE_NAME_EXTRA}_$TARGET.cwe

}

do_generate_rcy_cwe[depends] += "cwetool-native:do_populate_sysroot"
do_generate_rcy_cwe[depends] += "${PN}:do_install"
do_generate_rcy_cwe[depends] += "linux-quic:do_add_mbnhdr_and_hash"

do_generate_rcy_cwe() {
    if [ "${MACHINE}" = "swi-mdm9x28-ar758x-rcy" ]; then
        generate_rcy_cwe_target "ar758x"
    elif [ "${MACHINE}" = "swi-mdm9x40-ar759x-rcy" ]; then
        generate_rcy_cwe_target "ar759x"
    else
        echo "Unsupported machine '${MACHINE}'"
        exit 1
    fi
}

addtask generate_rcy_cwe before do_build
