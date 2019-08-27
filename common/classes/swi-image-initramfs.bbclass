DESCRIPTION = "An image with only the bare minimum to accelerate the boot process."

PACKAGE_INSTALL = "busybox mtd-utils-ubifs"

# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""

inherit swi-image

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_FSTYPES = "cpio tar.bz2"

PR = "0"

PACKAGE_EXCLUDE += "busybox-syslog busybox-udhcpc"

# Clean unecessary content
remove_entity() {
    if [ -e "$1" ] ; then
        printf "Removing %s from initramfs\n" "$1"
        rm -rf -- "$1"
    fi
}

fakeroot do_filter_rootfs () {
    cd ${IMAGE_ROOTFS}

    # Create basic folders
    for entry in bin dev lib mnt proc run sys tmp var; do
        mkdir -p $entry
        chown 755 $entry
    done

    # Populate rootfs with some devices
    [ -e "dev/console" ] || mknod dev/console c 5 1
    [ -e "dev/null" ] || mknod dev/null c 1 3
    [ -e "dev/urandom" ] || mknod dev/urandom c 1 9
    [ -e "dev/zero" ] || mknod dev/zero c 1 5

    # remove things not handled by garbage collection below.
    for item in ./etc/busybox.links.suid \
                ./lib/udev/rules.d \
                ./lib/libnss_files-*.so \
                ./lib/udev \
                ./bin/busybox.suid \
                ./usr/lib/opkg
    do
      remove_entity $item
    done

    # garbage collect: remove unreachable executables and libs
    printf "Garbage collecting initramfs ...\n"
    set -o pipefail # fail the below pipeline if the python program fails
    ${META_SWI_SCRIPTS}/gcfs.py | xargs -t rm -f
}

IMAGE_PREPROCESS_COMMAND += "do_filter_rootfs; "
