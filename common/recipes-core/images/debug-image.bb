DESCRIPTION = "A small image contains debug packages."

EXTENDED_SWI_IMAGE = "packagegroup-swi-image-target-ext"

# Add debug packages
IMAGE_INSTALL = "${EXTENDED_SWI_IMAGE}"

IMAGE_INSTALL += "initdbgscripts"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_TYPE ?= "debug"

PR = "${INC_PR}.0"

require debug-image.inc

