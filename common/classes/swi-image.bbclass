inherit core-image

IMAGE_LINGUAS = " "

LICENSE = "MIT"

create_deploy_dir_image() {
    mkdir -p "${DEPLOY_DIR_IMAGE}"
}

ROOTFS_PREPROCESS_COMMAND_append = "create_deploy_dir_image"

