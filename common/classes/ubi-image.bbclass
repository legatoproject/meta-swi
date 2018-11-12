# Helper class to generate a ubi image

# Create UBI image (for a specific page size)
create_ubi_image() {
    local page_size=$1

    local ubinize_cfg=$2

    local ubi_path=$3
    local ubi_link_path=$4

    local ubinize_args=''

    case $page_size in
    2k)
        ubinize_args="${UBINIZE_ARGS_2k}"
        ;;
    4k)
        ubinize_args="${UBINIZE_ARGS_4k}"
        ;;
    *)
        exit 1
        ;;
    esac

    ${STAGING_DIR_NATIVE}/usr/sbin/ubinize -o $ubi_path $ubinize_args $ubinize_cfg

    if [ -n "$ubi_link_path" ]; then
        rm -f $ubi_link_path
        ln -s $(basename $ubi_path) $ubi_link_path
    fi
}

