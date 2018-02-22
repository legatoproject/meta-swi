DESCRIPTION = "A small image just capable of allowing SWI products to boot."

CORE_SWI_IMAGE ?= "packagegroup-swi-image-target"
EXTENDED_SWI_IMAGE ?= "packagegroup-swi-image-target-ext"

IMAGE_INSTALL = "packagegroup-core-boot ${ROOTFS_PKGMANAGE_BOOTSTRAP} ${CORE_IMAGE_EXTRA_INSTALL} ${CORE_SWI_IMAGE}"

# Uncomment the following line to add debug packages
# IMAGE_INSTALL += " ${EXTENDED_SWI_IMAGE}"

IMAGE_LINGUAS = " "

LICENSE = "MIT"

inherit core-image

IMAGE_ROOTFS_SIZE ?= "8192"

IMAGE_TYPE ?= "minimal"

PR = "${INC_PR}.0"

# Only add Legato if this is a LEGATO_BUILD
def check_legato_pkg(d, package="legato-af"):
    legato_build = d.getVar('LEGATO_BUILD', True) or "false"
    if legato_build == "true":
        return package
    return ""

