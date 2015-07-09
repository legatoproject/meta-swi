# Helper class to generate a ubi image

# Create UBI image (for a specific page size)
create_ubi_image() {
    local page_size=$1

    local ubinize_cfg_tpl=$2

    local image_path=$3
    local ubi_path=$4
    local ubi_link_path=$5
    
    local ubinize_cfg=${WORKDIR}/gen_ubinize.cfg

    if ! [ -e "$image_path" ]; then
        echo "$image_path doesn't exist"
        exit 1
    fi

    echo "Using image: '$image_path'"

    cp -af $ubinize_cfg_tpl $ubinize_cfg
    sed -i -e "s|@@IMAGE_PATH@@|$image_path|g" $ubinize_cfg

    local ubinize_args=''

    case $page_size in
    2k)
        ubinize_args='-m 2048 -p 128KiB -s 2048'
        ;;
    4k)
        ubinize_args='-m 4096 -p 256KiB -s 4096'
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

