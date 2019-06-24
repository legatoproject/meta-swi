inherit core-image

IMAGE_LINGUAS = " "

LICENSE = "MIT"

INC_PR ?= "r0"
PR = "${INC_PR}.0"

create_deploy_dir_image() {
    mkdir -p "${DEPLOY_DIR_IMAGE}"
}

ROOTFS_PREPROCESS_COMMAND_append = "create_deploy_dir_image"

