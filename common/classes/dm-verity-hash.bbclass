# Helper class to generate a hash tree table for Dm-verity

# Create hash tree table bin file
create_dm_verity_hash() {
    local image_path=$1
    local dm_hash_path=$2
    local dm_hash_filename=$3
    local dm_args=$4

    # We should save the format log to ${dm_hash_path}.txt, So the other scripts can get require info from it
    ${STAGING_DIR_NATIVE}/usr/sbin/veritysetup format $image_path $dm_hash_path $dm_args > ${dm_hash_filename}
}


