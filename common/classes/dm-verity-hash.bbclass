# Helper class to generate a hash tree table for Dm-verity
inherit android-signing

# Create hash tree table bin file
create_dm_verity_hash() {
    local image_path="$1"
    local dm_hash_path="$2"
    local dm_hash_filename="$3"
    local dm_args=$4

    echo "Creating dm-verity hash for data[$image_path] hash[$dm_hash_path] @ $dm_hash_filename"

    if [ ! -e "$image_path" ]; then
        echo "Image $image_path does not exist"
        exit 1
    fi

    if [ ! -e "$dm_hash_path" ]; then
        echo "dm-verity hash does not exist, creating empty file."
        touch "$dm_hash_path"
    fi

    ${STAGING_DIR_NATIVE}/usr/sbin/veritysetup format "$image_path" "$dm_hash_path" $dm_args > "${dm_hash_filename}"
}

get_dm_root_hash() {
    local dm_root_hash_path=$1
    local dm_hash_filename=$2
    echo "Getting hash for $dm_hash_filename}"
    local root_hash=$(cat ${dm_hash_filename} | grep Root | awk -F' ' '{printf $3}')
    echo "... ${root_hash}"
    echo ${root_hash} > ${dm_root_hash_path}

    cp ${dm_root_hash_path} ${dm_root_hash_path}.unsigned

    # sign the image with single cert
    android_signature_add /rootfs "${dm_root_hash_path}" "${dm_root_hash_path}" testkey

    # sign the image with cert chain
    #android_signature_add /rootfs "${dm_root_hash_path}" "${dm_root_hash_path}" rootfs/Attestation \
    #   rootfs/AttestationCA.der rootfs/RootCA.der
}


