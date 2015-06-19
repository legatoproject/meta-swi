DESCRIPTION = "An image with only the bare minimum to accelerate the boot process."

PACKAGE_INSTALL = "initramfs-mdminit busybox"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE = "8192"

IMAGE_FSTYPES = "cpio.gz tar.bz2"

PR = "0"

PACKAGE_EXCLUDE += "busybox-syslog busybox-udhcpc"

fakeroot do_filter_rootfs () {

    cd ${IMAGE_ROOTFS}

    # Clean unecessary content
    remove_entity() {
        echo "Removing $file"
        rm -rf $file
    }

    for file in $(find); do
        if [[ "$file" == "./sbin/ldconfig" ]]; then
            remove_entity $file
        elif [[ "$file" == "./usr/lib/opkg" ]]; then
            remove_entity $file
        elif [[ "$file" == "./usr/bin/update-alternatives" ]]; then
            remove_entity $file
        elif echo $file | grep '\.suid'; then
            remove_entity $file
        elif [[ "$(readlink file)" == "/bin/busybox.suid" ]]; then
            remove_entity $file
        elif echo $file | grep '\./lib/'; then
            case $file in
                */ld-*) ;;
                */libc.*) ;;
                */libc-*) ;;
                *) remove_entity $file ;;
            esac
        fi
    done

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
}

IMAGE_PREPROCESS_COMMAND += "do_filter_rootfs; "
