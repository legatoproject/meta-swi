DESCRIPTION = "A small image just capable of allowing SWI products to boot."

CORE_SWI_IMAGE ?= "packagegroup-swi-image-target"

IMAGE_INSTALL = "packagegroup-core-boot ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL} ${CORE_SWI_IMAGE}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_TYPE ?= "minimal"

PR = "${INC_PR}.0"

