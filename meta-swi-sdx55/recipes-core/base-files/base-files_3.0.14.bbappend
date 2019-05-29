FLASH_MOUNTPOINT = "/mnt/flash"
FLASH_MOUNTPOINT_LEGATO = "/mnt/legato"
LEGATO_MOUNTPOINT = "/legato"

# Install all additional files/dirs
do_install_append() {
    install -m 0755 -d ${D}${FLASH_MOUNTPOINT}
    install -m 0755 -d ${D}${FLASH_MOUNTPOINT_LEGATO}
    install -m 0755 -d ${D}${LEGATO_MOUNTPOINT}
}

