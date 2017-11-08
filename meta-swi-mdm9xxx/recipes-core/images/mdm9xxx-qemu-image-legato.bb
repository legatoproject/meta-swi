SUMMARY = "Generate and install the legato image in the flash image of Qemu"

inherit legato

IMAGE_LINGUAS = " "

HOMEPAGE = "http://www.sierrawireless.com/"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

DEPENDS += "${GENERIC_BASEMACHINE}-image-minimal"

INC_PR = "r0"

do_compile[noexec] = "1"
do_generate_flashimage_legato[nostamp] = "1"

do_generate_flashimage_legato() {
    # Create an UBI image of Legato and install it into the NOR flash image of Qemu
    cd ${DEPLOY_DIR_IMAGE}

    QEMU_LEGATO_NAME="legato.ubi.img"
    /usr/sbin/ubinize -o ${QEMU_LEGATO_NAME}  -m 1 -p 256KiB $(find ${B}/../../../legato-image -name ubinize.cfg)

    echo "Installing Legato into flash image"
    # Legato partition is @0x4000000. See the device tree mdm9xxx-swi-qemu.dts.
    dd if=${QEMU_LEGATO_NAME} of=rawflash bs=256K seek=256 conv=notrunc
}

addtask generate_flashimage_legato after do_install_image and before do_packagedata

