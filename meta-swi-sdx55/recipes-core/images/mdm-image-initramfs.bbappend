# Include some extra packages if dm-verity is enabled
verity_packages = "${@bb.utils.contains('MACHINE_FEATURES', 'android-verity', \
                      ' libdevmapper', ' cryptsetup libgcrypt', d)}"
PACKAGE_INSTALL_append = "${@oe.utils.conditional('DM_VERITY_ENCRYPT', \
                                 'on', '${verity_packages}', '', d)}"

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
        elif echo "$file" | grep "./usr/lib/opkg"; then
            remove_entity $file
        elif echo "$file" | grep "./usr/lib/liblvm"; then
            remove_entity $file
        elif echo "$file" | grep "./usr/lib/liblzo2"; then
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
                */libdl*) ;;
                */librt*) ;;
                */libpthread*) ;;
                */libuuid*) ;;
                */libudev*) ;;
                */libcrypt*) ;;
                */libz.so*) ;;
                */libm*) ;;
                */libresolv*) ;;
                */libblkid*) ;;
                *) remove_entity $file ;;
            esac
        elif echo $file | grep -e "./usr/sbin/.*ubi"; then
            if [[ "$file" != "./usr/sbin/ubiattach"* ]] && [[ "$file" != "./usr/sbin/ubiblkvol"* ]] && [[ "$file" != "./usr/sbin/ubiblock" ]]; then
                remove_entity $file
            fi
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

