DEPENDS += " \
	edk2 \
	mtd-utils-native \
	cryptsetup-native \
	libarchive-native"

INC_PR = "r0"

inherit ubi-image
inherit dm-verity-hash
inherit set-files-attr

# start-scripts-find-partitions is required for sysvinit
IMAGE_INSTALL_append = "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', \
			'', ' start-scripts-find-partitions' ,d)}"
IMAGE_INSTALL_append = " start-scripts-firmware-links"

IMAGE_INSTALL_append = " kernel-modules"
IMAGE_INSTALL_append = " bsinfo-stub"
IMAGE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd', '' ,d)}"
IMAGE_INSTALL += "${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'systemd-machine-units', '' ,d)}"
IMAGE_INSTALL += "system-core-adbd"
IMAGE_INSTALL += "system-core-usb"
IMAGE_INSTALL += "volatile-binds"
IMAGE_INSTALL += "strace"
IMAGE_INSTALL += "reboot-daemon"
IMAGE_INSTALL += "cryptsetup"


def grep_and_awk(text, grepfor, awkfor):
    for line in text.split("\n"):
        if grepfor in line:
            fields = line.strip().split()
            return fields[awkfor]
    raise Exception("Text '%s' not found in:\n%s\n" % (grepfor, string))


def prepare_table(d, data_file, target_dev):
    import math, subprocess
    bsize = 4096
    blocks = math.ceil(os.path.getsize(data_file) / bsize)
    bstart = blocks + 1
    hoffset = blocks * bsize
    veritypath = d.getVar("STAGING_DIR_NATIVE") + "/usr/sbin/"

    # Build verity hash tree
    command = veritypath + "veritysetup --data-blocks=" + repr(blocks) + \
                         " --hash-offset=" + repr(hoffset) + \
                         " format " + data_file + " " + data_file

    subproc = subprocess.run(command.split(), \
                             stdout = subprocess.PIPE, stderr = subprocess.PIPE)

    if not 0 == subproc.returncode:
        raise Exception("prepare_table command: \n%s\nerror %d: \n%s\n" % \
                         (command, subproc.returncode, subproc.stderr))

    cmd_stdout = subproc.stdout.decode()

    # Extract root hash and salt from veritysetup output and populate dm table
    rhash = grep_and_awk(cmd_stdout, "Root", 2)
    salt = grep_and_awk(cmd_stdout, "Salt", 1)
    table = "1 " + target_dev + " " + target_dev + " " + repr(bsize) + " " + \
             repr(bsize) + " " + repr(blocks) + " " + repr(bstart) + \
             " sha256 " + rhash + " " + salt

    return table


def append_android_metadata(data_file, metadata):
    # Round-up file size to 32k boundary
    bsize = 32 * 1024
    dsize = os.path.getsize(data_file)

    # Read in file data
    df = open(data_file, "ab")

    # Pad with zeros to nearest 32k
    padding = "\0" * (bsize - (dsize % bsize))
    df.write(str.encode(padding))

    # Append metadata
    df.write(metadata)
    df.close()
    return


python android_verity_sign() {
    deploydir = d.getVar("IMGDEPLOYDIR")
    image_name = d.getVar("IMAGE_NAME")
    image = deploydir + "/" + image_name + ".rootfs.squashfs"

    if not os.path.isfile(image):
        raise Exception("android_verity_sign: file '%s' does not exist" % image)

    table = prepare_table(d, os.path.realpath(image), "/dev/ubiblock0_0")
    privkey = "testkey"
    metadata = generate_android_metadata(d, table, privkey)
    append_android_metadata(os.path.realpath(image), metadata)
    return
}

dm_verity_sign() {
    image_path="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.squashfs"
    dm_hash_path="${image_path}.hash"
    dm_hash_filename="${dm_hash_path}.txt"
    dm_root_hash_path="${image_path}.rhash"

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]] && [[ -e ${image_path} ]]; then
        create_dm_verity_hash "${image_path}" "${dm_hash_path}" "${dm_hash_filename}"
        get_dm_root_hash "${dm_root_hash_path}" "${dm_hash_filename}"
    fi
}


create_ubinize_config() {
    local cfg_path=$1
    local rootfs_type=$2
    local vid=0

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        local dm_hash_path=$3
        local dm_root_hash_path=$4
    fi

    local rootfs_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.rootfs.${rootfs_type}"

    echo \[sysfs_volume\] > $cfg_path
    echo mode=ubi >> $cfg_path
    echo image="$rootfs_path" >> $cfg_path
    echo vol_id=$vid >> $cfg_path
    let vid+=1

    if [[ "${rootfs_type}" = "squashfs" ]]; then
        echo vol_type=static >> $cfg_path
    else
        echo vol_type=dynamic >> $cfg_path
        echo vol_size="${UBI_ROOTFS_SIZE}" >> $cfg_path
    fi

    echo vol_name=rootfs >> $cfg_path
    echo vol_alignment=1 >> $cfg_path

    if [[ "${DM_VERITY_ENCRYPT}" = "on" ]]; then
        # dm-verity hash tree table followed after the rootfs
        # Init scripts will check this partition during boot up
        if [[ -s ${dm_hash_path} ]]; then
            echo >> $cfg_path
            echo \[hash_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_hash_path" >> $cfg_path
            echo vol_id=$vid >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_hs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
            let vid+=1
        fi

        #  dm-verity root hash is following the hash
        if [[ -s ${dm_root_hash_path} ]]; then
            echo >> $cfg_path
            echo \[rh_volume\] >> $cfg_path
            echo mode=ubi >> $cfg_path
            echo image="$dm_root_hash_path" >> $cfg_path
            echo vol_id=$vid >> $cfg_path
            echo vol_type=static >> $cfg_path
            echo vol_name=rootfs_rhs >> $cfg_path
            echo vol_alignment=1 >> $cfg_path
            let vid+=1
        fi
    fi
}

prepare_ubi_ps() {
    local page_size=$1
    local image_type=
    local ubinize_cfg=
    local image_path=
    local dm_hash_path=
    local dm_hash_filename=
    local dm_root_hash_path=
    local ubi_path=
    local ubi_link_path=

    mkdir -p "${IMGDEPLOYDIR}"

    for rootfs_type in ubifs squashfs; do
        image_type=${rootfs_type}
        if [[ "${rootfs_type}" != "squashfs" ]]; then
            image_type=${page_size}.${rootfs_type}
        fi

        ubinize_cfg="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${image_type}.ubinize.cfg"
        image_path="${IMGDEPLOYDIR}/${IMAGE_NAME}${IMAGE_NAME_SUFFIX}.${image_type}"

        # Now Dm-verity only work with squashfs
        if [ "${DM_VERITY_ENCRYPT}" = "on" -a "${rootfs_type}" = "squashfs" ]; then
            dm_hash_path="${image_path}.hash"
            dm_hash_filename="${dm_hash_path}.txt"
            dm_root_hash_path="${image_path}.rhash"

            # Check if necessary files were created
            if [[ -s $dm_hash_path ]] && [[ -s "$dm_hash_filename" ]] && \
               [[ -s "$dm_root_hash_path" ]]; then
                create_ubinize_config ${ubinize_cfg} ${image_type} ${dm_hash_path} ${dm_root_hash_path}
            else
                # Android-verity allows everything packed in one volume
                create_ubinize_config ${ubinize_cfg} ${image_type}
            fi
        else
            create_ubinize_config ${ubinize_cfg} ${image_type}
        fi

        ubi_path="${IMGDEPLOYDIR}/${IMAGE_NAME}.${rootfs_type}.${page_size}.ubi"
        ubi_link_path="${IMGDEPLOYDIR}/${IMAGE_LINK_NAME}.${rootfs_type}.${page_size}.ubi"

        create_ubi_image $page_size $ubinize_cfg $ubi_path $ubi_link_path
    done
}

prepare_ubi() {
    prepare_ubi_ps '2k'
    prepare_ubi_ps '4k'

    cd ${IMGDEPLOYDIR}

    # Default image (no bs suffix) to 4k + squashfs
    ubi_link_path_def="${IMAGE_LINK_NAME}.squashfs.4k.ubi"
    ubi_link_path_def_2k="${IMAGE_LINK_NAME}.squashfs.2k.ubi"

    ubi_link_path="${IMAGE_LINK_NAME}.4k.ubi"
    ubi_link_path_2k="${IMAGE_LINK_NAME}.2k.ubi"

    rm -f $ubi_link_path $ubi_link_path_2k
    ln -s $ubi_link_path_def $ubi_link_path
    ln -s $ubi_link_path_def_2k $ubi_link_path_2k

    ubi_link_path="${IMAGE_LINK_NAME}.ubi"
    rm -f $ubi_link_path
    ln -s $ubi_link_path_def $ubi_link_path
}

# Select verity data generation step if DM_VERITY_ENCRYPT is 'on'
verity_signature = "${@bb.utils.contains('MACHINE_FEATURES', 'android-verity', \
                      'android_verity_sign', 'dm_verity_sign' ,d)}"
do_image_complete[postfuncs] += "${@oe.utils.conditional('DM_VERITY_ENCRYPT', \
                                 'on', '${verity_signature}', '', d)}"
do_image_complete[postfuncs] += "prepare_ubi"

default_rootfs_ps() {
    cd ${IMGDEPLOYDIR}

    # Default rootfs to ubi for 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.ubi  ${IMAGE_LINK_NAME}.4k.default

    # Default rootfs to 4k
    ln -sf ${IMAGE_LINK_NAME}.4k.default ${IMAGE_LINK_NAME}.default
}

do_image_complete[postfuncs] += "default_rootfs_ps"

# Re-enable fetch & unpack tasks, because of bug(s) in Yocto 1.6 .
do_fetch2[dirs] = "${DL_DIR}"
python do_fetch2() {
    bb.build.exec_func('base_do_fetch', d)
}

addtask fetch2

do_unpack2[dirs] = "${WORKDIR}"
python do_unpack2() {
    bb.build.exec_func('base_do_unpack', d)
}

addtask unpack2 before do_rootfs

do_setfileattr() {
    if [[ "x${SMACK_ATTR_NAME}" != "x" ]]; then
        if [[ "x${SMACK_ATTR_VALUE}" != "x" ]]; then
            set_file_attr ${IMAGE_ROOTFS}
        fi
    fi
}

IMAGE_PREPROCESS_COMMAND += "do_setfileattr; "

ROOTFS_POSTPROCESS_COMMAND_append = " gen_buildprop;"
EXTRA_IMAGE_FEATURES += "${@bb.utils.contains('DISTRO_FEATURES','ro-rootfs','read-only-rootfs','',d)}"
gen_buildprop() {
    mkdir -p ${IMAGE_ROOTFS}/cache
}

require mdm-image-cwe.inc
