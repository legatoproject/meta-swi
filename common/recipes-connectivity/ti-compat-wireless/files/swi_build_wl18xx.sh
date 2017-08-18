export PATH__ROOT=`pwd`
. configuration.sh
. setup-env
# Pretty colors
GREEN="\033[01;32m"
YELLOW="\033[01;33m"
NORMAL="\033[00m"
BLUE="\033[34m"
RED="\033[31m"
PURPLE="\033[35m"
CYAN="\033[36m"
UNDERLINE="\033[02m"

function print_highlight()
{
    echo -e "   ${YELLOW}***** $1 ***** ${NORMAL} "
}

function usage ()
{
    echo ""
    echo "This script build all/one of the relevent wl18xx software package."
    echo "A web guide can be found here : http://processors.wiki.ti.com/index.php/WL18xx_System_Build_Scripts"
    echo ""
    echo "Usage : "
    echo ""
    echo "Building full package : "
    echo "        ./build_wl18xx.sh init         <head|TAG>  [ Download and Update w/o build  ] "
    echo "                          update       <head|TAG>  [ Update to specific TAG & Build ] "
    echo "                          clean                    [ Clean & Build                  ] "
    echo "                          <empty>                  [ Build w/o update               ] "
    echo "                          check_updates            [ Check for build script updates ] "
    echo ""
    echo "Building specific component :"
    echo "                          hostapd                  [ Clean & Build hostapd          ] "
    echo "                          wpa_supplicant           [ Clean & Build wpa_supplicant   ] "
    echo "                          modules                  [ Clean & Build driver modules   ] "
    echo "                          firmware                 [ Install firmware file          ] "
    echo "                          scripts                  [ Install scripts                ] "
    echo "                          utils                    [ Clean & Build scripts          ] "
    echo "                          iw                       [ Clean & Build iw               ] "
    echo "                          openssl                  [ Clean & Build openssll         ] "
    echo "                          libnl                    [ Clean & Build libnl            ] "
    echo "                          crda                     [ Clean & Build crda             ] "
    echo "                          patch_kernel             [ Apply provided kernel patches  ] "
    echo "                          uim                      [ Clean & Build uim              ] "
    echo "                          bt-firmware              [ Install Bluetooth init scripts ] "
    exit 1
}

function assert_no_error()
{
    if [ $? -ne 0 ]; then
        echo "****** ERROR $? $@*******"
        exit 1
    fi
        echo "****** $1 *******"
}

function repo_id()
{
    i="0"
    while [ $i -lt ${#repositories[@]} ]; do
        [ $1 == "${repositories[i]}" ] && echo $i
        i=$[$i + 3]
    done
}

function repo_url()
{
    echo "${repositories[`repo_id $1` + 1]}"
}

function repo_branch()
{
    echo "${repositories[`repo_id $1` + 2]}"
}

function path()
{
    i="0"
    while [ $i -lt "${#paths[@]}" ]; do
        [ $1 == "${paths[i]}" ] && echo "${paths[i + 1]}"
        i=$[$i + 2]
    done
}

function set_path()
{
    i="0"
    while [ $i -lt "${#paths[@]}" ]; do
        [ $1 == "${paths[i]}" ] && paths[i+1]=$2
        i=$[$i + 2]
    done
}

function repo_path()
{
    echo `path src`/$1
}

function cd_path()
{
    cd `path $1`
}

function cd_repo()
{
    cd `repo_path $1`
}

function cd_back()
{
    cd - > /dev/null
}

function check_for_build_updates()
{
        git fetch
        count=`git status -uno | grep behind | wc -l`
        if [ $count -ne 0 ]
        then
                echo ""
        echo "*** Please note, there is an updated build script avilalable ***"
        echo "*** Use 'git pull' to get the latest update. ***"
        echo ""
        sleep 5
        fi
}

function read_kernel_version()
{
        filename=$KERNEL_PATH/Makefile

        if [ ! -f $filename ]
        then
            KERNEL_VERSION=0
            KERNEL_PATCHLEVEL=0
            KERNEL_SUBLEVEL=0
            echo "No Makefile was found. Kernel version was set to default."
        else
            exec 6< $filename
            read version <&6
            read patchlevel <&6
            read sublevel <&6
            exec 6<&-

            KERNEL_VERSION=$(echo $version|sed 's/[^0-9]//g')
            KERNEL_PATCHLEVEL=$(echo $patchlevel|sed 's/[^0-9]//g')
            KERNEL_SUBLEVEL=$(echo $sublevel|sed 's/[^0-9]//g')
            echo "Makefile was found. Kernel version was set to $KERNEL_VERSION.$KERNEL_PATCHLEVEL.$KERNEL_SUBLEVEL."
        fi
    [ $VERIFY_CONFIG ] && ./verify_kernel_config.sh $KERNEL_PATH/.config
}

#----------------------------------------------------------j
function setup_environment()
{
    if [ ! -e setup-env ]
    then
        echo "No setup-env"
        exit 1
    fi

    #if a rootfs path is set - replace the default.
    if [[ "$ROOTFS" != "DEFAULT" ]]
    then
        echo " Changing ROOTFS path to $ROOTFS"
        set_path filesystem $ROOTFS
        [ ! -d $ROOTFS ] && echo "Error ROOTFS: $ROOTFS dir does not exist" && exit 1
    fi
    #if no toolchain path is set - download it.
    if [[ "$TOOLCHAIN_PATH" == "DEFAULT" ]]
    then
        echo " Setting TOOLCHAIN_PATH path to default"
        export TOOLCHAIN_PATH=`path toolchain`/arm/bin
        DEFAULT_TOOLCHAIN=1
    fi

    #if no kernel path is set - download it.
    if [[ "$KERNEL_PATH" == "DEFAULT" ]]
    then
        echo " Setting KERNEL_PATH path to default"
        export KERNEL_PATH=`repo_path kernel`
        DEFAULT_KERNEL=1
    else
        echo " Using user defined kernel"
        [ ! -d $KERNEL_PATH ] && echo "Error KERNEL_PATH: $KERNEL_PATH dir does not exist" && exit 1
    fi

    export PROCESSORS_NUMBER=$(egrep '^processor' /proc/cpuinfo | wc -l)
    export PKG_CONFIG_PATH=`path filesystem`/lib/pkgconfig
    export INSTALL_PREFIX=`path filesystem`
    export LIBNL_PATH=`repo_path libnl`
    export KLIB=`path filesystem`
    export KLIB_BUILD=${KERNEL_PATH}
        export GIT_TREE=`repo_path driver`
        export PATH=$TOOLCHAIN_PATH:$PATH

}

function setup_filesystem_skeleton()
{
    mkdir -p `path filesystem`/usr/bin
    mkdir -p `path filesystem`/etc
    mkdir -p `path filesystem`/etc/init.d
    mkdir -p `path filesystem`/etc/rcS.d
    mkdir -p `path filesystem`/usr/lib/crda
    mkdir -p `path filesystem`/lib/firmware/ti-connectivity
    mkdir -p `path filesystem`/usr/share/wl18xx
    mkdir -p `path filesystem`/usr/sbin/wlconf
    mkdir -p `path filesystem`/usr/sbin/wlconf/official_inis
     mkdir -p `path filesystem`/etc/wireless-regdb/pubkeys
}

function setup_directories()
{
    i="0"
    while [ $i -lt ${#paths[@]} ]; do
        mkdir -p ${paths[i + 1]}
        i=$[$i + 2]
    done
    setup_filesystem_skeleton

}

function setup_repositories()
{
    i="0"
    while [ $i -lt ${#repositories[@]} ]; do
        url=${repositories[$i + 1]}
        name=${repositories[$i]}
        echo -e "${NORMAL}Cloning into: ${GREEN} $name ${NORMAL}"
        #Skip kernel clone if it was user defined
        [ "$name" != "kernel" -o "$DEFAULT_KERNEL" ] && [ ! -d `repo_path $name` ] && git clone $url `repo_path $name`
        i=$[$i + 3]
    done
}

function setup_branches()
{
    i="0"
    while [ $i -lt ${#repositories[@]} ]; do
        name=${repositories[$i]}
        url=${repositories[$i + 1]}
        branch=${repositories[$i + 2]}
        checkout_type="branch"
        #for all the openlink repo. we use a tag if provided.
        [ "$name" == "kernel" ] && [ -z "$DEFAULT_KERNEL" ] && i=$[$i + 3] && continue
        cd_repo $name
        echo -e "\n${NORMAL}Checking out branch ${GREEN}$branch  ${NORMAL}in repo ${GREEN}$name ${NORMAL} "
        git checkout $branch
        git fetch origin
        git fetch origin --tags
        if [[ "$url" == *git.ti.com* ]]
        then
           [[ -n $RESET ]] && echo -e "${PURPLE}Reset to latest in repo ${GREEN}$name ${NORMAL} branch  ${GREEN}$branch ${NORMAL}"  && git reset --hard origin/$branch
           [[ -n $USE_TAG ]] && git reset --hard $USE_TAG  && echo -e "${NORMAL}Reset to tag ${GREEN}$USE_TAG   ${NORMAL}in repo ${GREEN}$name ${NORMAL} "
        fi
        cd_back
        i=$[$i + 3]
    done
}

function setup_toolchain()
{
    if [ ! -f `path downloads`/arm-toolchain.tar.bz2 ]; then
        echo "Setting toolchain"
        wget ${toolchain[0]} -O `path downloads`/arm-toolchain.tar.bz2
        tar -xjf `path downloads`/arm-toolchain.tar.bz2 -C `path toolchain`
        mv `path toolchain`/* `path toolchain`/arm
    fi
}

function build_intree()
{
    cd_repo driver
    export KERNEL_PATH=`repo_path driver`
    read_kernel_version
    [ $CONFIG ] && cp `path configuration`/kernel_$KERNEL_VERSION.$KERNEL_PATCHLEVEL.config `repo_path driver`/.config
    [ $CLEAN ] && make clean
    [ $CLEAN ] && assert_no_error

    make -j${PROCESSORS_NUMBER} zImage
    make -j${PROCESSORS_NUMBER} am335x-evm.dtb
    make -j${PROCESSORS_NUMBER} am335x-bone.dtb
    make -j${PROCESSORS_NUMBER} am335x-boneblack.dtb
    make -j${PROCESSORS_NUMBER} modules
    INSTALL_MOD_PATH=`path filesystem` make -j${PROCESSORS_NUMBER} modules_install
    cp `repo_path driver`/arch/arm/boot/zImage `path tftp`/zImage
    cp `repo_path driver`/arch/arm/boot/dts/am335x-*.dtb `path tftp`/

    assert_no_error
    cd_back
}

function build_uimage()
{
    cd_repo kernel
    [ -z $NO_CONFIG ] && cp `path configuration`/kernel_$KERNEL_VERSION.$KERNEL_PATCHLEVEL.config `repo_path kernel`/.config
    [ -z $NO_CLEAN ] && make clean
    [ -z $NO_CLEAN ] && assert_no_error

    if [ "$KERNEL_VERSION" -eq 3 ] && [ "$KERNEL_PATCHLEVEL" -eq 2 ]
    then
        make -j${PROCESSORS_NUMBER} uImage
        cp `repo_path kernel`/arch/arm/boot/uImage `path tftp`/uImage
    else
        if [ -z $NO_DTB ]
        then
            make -j${PROCESSORS_NUMBER} zImage
            make -j${PROCESSORS_NUMBER} am335x-evm.dtb
            make -j${PROCESSORS_NUMBER} am335x-bone.dtb
            make -j${PROCESSORS_NUMBER} am335x-boneblack.dtb
        make -j${PROCESSORS_NUMBER} modules
        INSTALL_MOD_PATH=`path filesystem` make -j${PROCESSORS_NUMBER} modules_install
            cp `repo_path kernel`/arch/arm/boot/zImage `path tftp`/zImage
            cp `repo_path kernel`/arch/arm/boot/dts/am335x-*.dtb `path tftp`/
        else
            LOADADDR=0x80008000 make -j${PROCESSORS_NUMBER} uImage.am335x-evm
            cp `repo_path kernel`/arch/arm/boot/uImage.am335x-evm `path tftp`/uImage
        fi
    fi
    assert_no_error
    cd_back
}

function generate_compat()
{
        cd_repo backports
        python ./gentree.py --clean `repo_path driver` `path compat_wireless`
        cd_back
}

function build_modules()
{
    generate_compat
    cd_repo compat_wireless
    if [ -n "$KERNEL_VARIANT" ] && [ -d "$PATH__ROOT/patches/driver_patches/$KERNEL_VARIANT" ]; then
        for i in $PATH__ROOT/patches/driver_patches/$KERNEL_VARIANT/*.patch; do
            print_highlight "Applying driver patch: $i"
            patch -p1 < $i;
            assert_no_error
        done
    fi
    if [ -z $NO_CLEAN ]; then
        make clean
    fi
    make defconfig-wl18xx
    make -j${PROCESSORS_NUMBER}
    assert_no_error
    #find . -name \*.ko -exec cp {} `path debugging`/ \;
    find . -name \*.ko -exec ${CROSS_COMPILE}strip -g {} \;

    make  modules_install
    assert_no_error
    cd_back
}

function build_openssl()
{
    cd_repo openssl
    [ -z $NO_CONFIG ] && ./Configure linux-generic32
    [ -z $NO_CLEAN ] && make clean
    [ -z $NO_CLEAN ] && assert_no_error
    LDFLAGS+=" ${YOCTO_LDFLAGS}" make CC="${YOCTO_CC}"
    assert_no_error
    make install_sw
    assert_no_error
    cd_back
}


function build_iw()
{
    cd_repo iw
    [ -z $NO_CLEAN ] && make clean
    [ -z $NO_CLEAN ] && assert_no_error
    CC=${YOCTO_CC} LIBS+=" -lpthread -lm" LDFLAGS+=" ${YOCTO_LDFLAGS}" make V=1
    assert_no_error
    DESTDIR=`path filesystem` make install
    assert_no_error
    cd_back
}
function build_libnl()
{
    cd_repo libnl
    [ -z $NO_CONFIG ] && ./autogen.sh
    [ -z $NO_CONFIG ] && ./configure --prefix=`path filesystem` --host=${ARCH} CC="${YOCTO_CC}" AR=${CROSS_COMPILE}ar
    ([ -z $NO_CONFIG ] || [ -z $NO_CLEAN ]) && make clean
    [ -z $NO_CLEAN ] && assert_no_error
    make
    assert_no_error
    make install
    assert_no_error
    cd_back
}

function build_wpa_supplicant()
{
    cd `repo_path hostap`/wpa_supplicant
    [ -z $NO_CONFIG ] && cp android.config .config
    [ -n "$SYSLOG_EN" ] && echo "Enable DEBUG_SYSLOG config" && sed -i "/#CONFIG_DEBUG_SYSLOG=y/ s/# *//" .config
    CONFIG_LIBNL32=y DESTDIR=`path filesystem` make clean
    assert_no_error
    CONFIG_LIBNL32=y DESTDIR=`path filesystem` CFLAGS+=" -I`path filesystem`/usr/local/ssl/include -I`repo_path libnl`/include" LDFLAGS+=" ${YOCTO_LDFLAGS}" LIBS+=" -L`path filesystem`/lib -L`path filesystem`/usr/local/ssl/lib -lssl -lcrypto -lm -ldl -lpthread" LIBS_p+=" -L`path filesystem`/lib -L`path filesystem`/usr/local/ssl/lib -lssl -lcrypto -lm -ldl -lpthread" make -j${PROCESSORS_NUMBER} CC="${YOCTO_CC}" LD=${CROSS_COMPILE}ld AR=${CROSS_COMPILE}ar
    assert_no_error
    CONFIG_LIBNL32=y DESTDIR=`path filesystem` make install
    assert_no_error
    cd_back
    cp `repo_path scripts_download`/conf/*_supplicant.conf  `path filesystem`/etc/
}

function build_hostapd()
{
    cd `repo_path hostap`/hostapd
    [ -z $NO_CONFIG ] && cp android.config .config
    [ -z $NO_UPNP ] && echo "Enable UPNP config" && sed -i "/#CONFIG_WPS_UPNP=y/ s/# *//" .config
    CONFIG_LIBNL32=y DESTDIR=`path filesystem` make clean
    assert_no_error
    CONFIG_LIBNL32=y DESTDIR=`path filesystem` CFLAGS+=" -I`path filesystem`/usr/local/ssl/include -I`repo_path libnl`/include" LDFLAGS+=" ${YOCTO_LDFLAGS}" LIBS+=" -L`path filesystem`/lib -L`path filesystem`/usr/local/ssl/lib -lssl -lcrypto -lm -ldl -lpthread" LIBS_p+=" -L`path filesystem`/lib -L`path filesystem`/usr/local/ssl/lib -lssl -lcrypto -lm -ldl -lpthread" make -j${PROCESSORS_NUMBER} CC="${YOCTO_CC}" LD=${CROSS_COMPILE}ld AR=${CROSS_COMPILE}ar
    assert_no_error
    CONFIG_LIBNL32=y DESTDIR=`path filesystem` make install
    assert_no_error
    cd_back
    cp `repo_path scripts_download`/conf/hostapd.conf  `path filesystem`/etc/
}

function build_crda()
{
    cp `repo_path wireless_regdb`/regulatory.bin `path filesystem`/usr/lib/crda/regulatory.bin
    cp `repo_path crda`/pubkeys/* `path filesystem`/etc/wireless-regdb/pubkeys/
    cd_repo crda

    [ -z $NO_CLEAN ] && DESTDIR=`path filesystem` make clean
    [ -z $NO_CLEAN ] && assert_no_error
    PKG_CONFIG_LIBDIR="`path filesystem`/lib/pkgconfig" PKG_CONFIG_PATH="`path filesystem`/usr/local/ssl/lib/pkgconfig" DESTDIR=`path filesystem` CFLAGS+=" -I`path filesystem`/usr/local/ssl/include -I`path filesystem`/include -L`path filesystem`/usr/local/ssl/lib -L`path filesystem`/lib" LDFLAGS+=" ${YOCTO_LDFLAGS}" LDLIBS+=" "-lpthread V=1 USE_OPENSSL=1 make -j${PROCESSORS_NUMBER} all_noverify CC="${YOCTO_CC}" LD=${CROSS_COMPILE}ld AR=${CROSS_COMPILE}ar
    rm libreg.so
    CFLAGS+=" -I`path filesystem`/usr/local/ssl/include -I`path filesystem`/include -L`path filesystem`/usr/local/ssl/lib -L`path filesystem`/lib ${YOCTO_LDFLAGS}" make libreg.so CC="${YOCTO_CC}"
    assert_no_error
        DESTDIR=`path filesystem` make install
        assert_no_error
    cd_back
}

function build_calibrator()
{
    cd_repo ti_utils
    [ -z $NO_CLEAN ] && NFSROOT=`path filesystem` make clean
    [ -z $NO_CLEAN ] && assert_no_error
    NLVER=3 NLROOT=`repo_path libnl`/include NFSROOT=`path filesystem` LDFLAGS+=" ${YOCTO_LDFLAGS}" LIBS+=" "-lpthread make CC="${YOCTO_CC}"
    assert_no_error
    NFSROOT=`path filesystem` make install
    #assert_no_error
    cp -f `repo_path ti_utils`/hw/firmware/wl1271-nvs.bin `path filesystem`/lib/firmware/ti-connectivity
    cd_back
}

function build_wlconf()
{
    files_to_copy="dictionary.txt struct.bin default.conf wl18xx-conf-default.bin README example.conf example.ini configure-device.sh"
    cd `repo_path ti_utils`/wlconf
    if [ -z $NO_CLEAN ]; then
        NFSROOT=`path filesystem` make clean
        assert_no_error
        for file_to_copy in $files_to_copy; do
            rm -f `path filesystem`/usr/sbin/wlconf/$file_to_copy
        done
        rm -f `path filesystem`/usr/sbin/wlconf/official_inis/*
    fi
    NFSROOT=`path filesystem` LDFLAGS+=" ${YOCTO_LDFLAGS}" make CC="${YOCTO_CC}" LD=${CROSS_COMPILE}ld
    assert_no_error

    # install
    cp -f `repo_path ti_utils`/wlconf/wlconf `path filesystem`/usr/sbin/wlconf
    chmod 755 `path filesystem`/usr/sbin/wlconf
    for file_to_copy in $files_to_copy; do
        cp $file_to_copy `path filesystem`/usr/sbin/wlconf/$file_to_copy
        echo "echoying files $file_to_copy"
    done
    cp official_inis/* `path filesystem`/usr/sbin/wlconf/official_inis/
    cd_back
}

function build_fw_download()
{
    cp `repo_path fw_download`/*.bin `path filesystem`/lib/firmware/ti-connectivity
}

function patch_kernel()
{
    [ ! -d $KERNEL_PATH ] && echo "Error KERNEL_PATH: $KERNEL_PATH dir does not exist" && exit 1
    cd $KERNEL_PATH
    echo "using kernel: $KERNEL_PATH"
    if [ -d "$PATH__ROOT/patches/kernel_patches/$KERNEL_VARIANT" ]; then
        read -p "Branch name to use? (will be created if doesn't exist)" -e branchname
        if git show-ref --verify --quiet "refs/heads/$branchname"; then
            echo "Branch name $branchname already exists, trying to use it..."
            git checkout $branchname
        else
            echo "Creating branch $branchname and switching to it"
            git checkout -b $branchname
        fi
        assert_no_error
        for i in $PATH__ROOT/patches/kernel_patches/$KERNEL_VARIANT/*.patch; do
            git am $i;
            assert_no_error
        done
    fi
    assert_no_error
    cd_back
}

function build_uim()
{
    cd_repo uim
    [ -z $NO_CLEAN ] && NFSROOT=`path filesystem` make clean
    [ -z $NO_CLEAN ] && assert_no_error
    LDFLAGS+=" ${YOCTO_LDFLAGS}" make CC="${YOCTO_CC}"
    assert_no_error
        install -m 0755 uim `path filesystem`/usr/bin
    install -m 0755 `repo_path uim`/scripts/uim-sysfs `path filesystem`/etc/init.d/
    cd `path filesystem`/etc/rcS.d/
    ln -sf  ../init.d/uim-sysfs S03uim-sysfs
    assert_no_error
    cd_back
}

function build_bt_firmware()
{
    cd_repo bt-firmware
    for i in `repo_path bt-firmware`/initscripts/*.bts; do
        echo "Installing bluetooth init script: $i"
        install -m 0755 $i `path filesystem`/lib/firmware/
        assert_no_error
    done
}

function build_scripts_download()
{
    cd_repo scripts_download
    echo "Copying scripts"
    scripts_download_path=`repo_path scripts_download`
    for script_dir in `ls -d $scripts_download_path`/*/
    do
        echo "Copying everything from ${script_dir} to `path filesystem`/usr/share/wl18xx directory"
        cp -rf ${script_dir}/* `path filesystem`/usr/share/wl18xx
    done
    cd_back
}

function clean_kernel()
{
    [ "$DEFAULT_KERNEL" ] && echo "Cleaning kernel folder"
    [ "$DEFAULT_KERNEL" ] && cd_repo kernel
    [ "$DEFAULT_KERNEL" ] && git clean -fdx > /dev/null
}

function clean_outputs()
{
    if [[ "$ROOTFS" == "DEFAULT" ]]
    then
        echo "Cleaning outputs"
        rm -rf `path filesystem`/*
        rm -f `path outputs`/*
   fi
}

function build_outputs()
{
    if [[ "$ROOTFS" == "DEFAULT" ]]
    then
        echo "Building outputs"
        cd_path filesystem
        tar cpjf `path outputs`/${tar_filesystem[0]} .
        cd_back

        # Copy kernel files only if default kernel is used(for now)
        if [[ $DEFAULT_KERNEL -eq 1 ]]
        then
            if [ "$KERNEL_VERSION" -eq 3 ] && [ "$KERNEL_PATCHLEVEL" -eq 2 ]
            then
                cp `path tftp`/uImage `path outputs`/uImage
            else
                if [ -z $NO_DTB ]
                then
                    cp `path tftp`/zImage `path outputs`/zImage
                    cp `path tftp`/*.dtb `path outputs`/
                else
                    cp `path tftp`/uImage `path outputs`/uImage
                fi
            fi
        fi
    fi
}

function install_outputs()
{
    echo "Installing outputs"
    tftp_path=${setup[2]}
    sitara_left_path=${setup[5]}
    sitara_right_path=${setup[8]}

    cp `path outputs`/uImage ${tftp_path}
    cp `path outputs`/${tar_filesystem[0]} $sitara_left_path
    cp `path outputs`/${tar_filesystem[0]} $sitara_right_path

    cd $sitara_left_path
    tar xjf ${tar_filesystem[0]}
    cd_back

    cd $sitara_right_path
    tar xjf ${tar_filesystem[0]}
    cd_back
}

function set_files_to_verify()
{
        files_to_verify=(
        # skeleton path
        # source path
        # pattern in output of file

        `path filesystem`/usr/local/sbin/wpa_supplicant
        `repo_path hostap`/wpa_supplicant/wpa_supplicant
        "ELF 32-bit LSB[ ]*executable, ARM"

        `path filesystem`/usr/local/bin/hostapd
        `repo_path hostap`/hostapd/hostapd
        "ELF 32-bit LSB[ ]*executable, ARM"

        `path filesystem`/sbin/crda
        `repo_path crda`/crda
        "ELF 32-bit LSB[ ]*executable, ARM"

        `path filesystem`/usr/lib/crda/regulatory.bin
        `repo_path wireless_regdb`/regulatory.bin
        "CRDA wireless regulatory database file"

        `path filesystem`/lib/firmware/ti-connectivity/wl18xx-fw-4.bin
        `repo_path fw_download`/wl18xx-fw-4.bin
        "data"

        `path filesystem`/lib/modules/$KERNEL_VERSION.$KERNEL_PATCHLEVEL.*/updates/drivers/net/wireless/ti/wl18xx/wl18xx.ko
        `path compat_wireless`/drivers/net/wireless/ti/wl18xx/wl18xx.ko
        "ELF 32-bit LSB[ ]*relocatable, ARM"

        `path filesystem`/lib/modules/$KERNEL_VERSION.$KERNEL_PATCHLEVEL.*/updates/drivers/net/wireless/ti/wlcore/wlcore.ko
        `path compat_wireless`/drivers/net/wireless/ti/wlcore/wlcore.ko
        "ELF 32-bit LSB[ ]*relocatable, ARM"

        #`path filesystem`/usr/bin/calibrator
        #`repo_path ti_utils`/calibrator
        #"ELF 32-bit LSB[ ]*executable, ARM"

        `path filesystem`/usr/sbin/wlconf/wlconf
        `repo_path ti_utils`/wlconf/wlconf
        "ELF 32-bit LSB[ ]*executable, ARM"
        )
}

function get_tag()
{
       i="0"
       while [ $i -lt ${#repositories[@]} ]; do
               name=${repositories[$i]}
               url=${repositories[$i + 1]}
        branch=${repositories[$i + 2]}
        checkout_type="branch"
        cd_repo $name
        if [[ "$url" == *git.ti.com* ]]
        then
                echo -e "${PURPLE}Describe of ${NORMAL} repo : ${GREEN}$name ${NORMAL} "  ;
                git describe
        fi
               cd_back
               i=$[$i + 3]
       done
}



function admin_tag()
{
    i="0"
    while [ $i -lt ${#repositories[@]} ]; do
        name=${repositories[$i]}
        url=${repositories[$i + 1]}
        branch=${repositories[$i + 2]}
        checkout_type="branch"
        cd_repo $name
        if [[ "$url" == *git.ti.com* ]]
        then
                echo -e "${PURPLE}Adding tag ${GREEN} $1 ${NORMAL} to repo : ${GREEN}$name ${NORMAL} "  ;
                git show --summary
                read -p "Do you want to tag this commit ?" yn
                case $yn in
                    [Yy]* )  git tag -a $1 -m "$1" ;
                             git push --tags ;;
                    [Nn]* ) echo -e "${PURPLE}Tag was not applied ${NORMAL} " ;;

                    * ) echo "Please answer yes or no.";;
                esac

        fi
        cd_back
        i=$[$i + 3]
    done
}


function verify_skeleton()
{
    echo "Verifying filesystem skeleton..."

        set_files_to_verify

    i="0"
    while [ $i -lt ${#files_to_verify[@]} ]; do
        skeleton_path=${files_to_verify[i]}
        source_path=${files_to_verify[i + 1]}
        file_pattern=${files_to_verify[i + 2]}
        file $skeleton_path | grep "${file_pattern}" >/dev/null
        if [ $? -eq 1 ]; then
        echo -e "${RED}ERROR " $skeleton_path " Not found ! ${NORMAL}"
        #exit
        fi

        md5_skeleton=$(md5sum $skeleton_path | awk '{print $1}')
        md5_source=$(md5sum $source_path     | awk '{print $1}')
        if [ $md5_skeleton != $md5_source ]; then
            echo "ERROR: file mismatch"
            echo $skeleton_path
            exit 1
        fi
        i=$[$i + 3]
    done

    which regdbdump > /dev/null
    if [ $? -eq 0 ]; then
        regdbdump `path filesystem`/usr/lib/crda/regulatory.bin > /dev/null
        if [ $? -ne 0 ]; then
                   echo "Please update your public key used to verify the DB"
               fi
    fi
}

function verify_installs()
{
    apps_to_verify=(
     libtool
     python-m2crypto
     bison
     flex
    )

    i="0"
    while [ $i -lt ${#apps_to_verify[@]} ]; do
        if !( dpkg-query -s ${apps_to_verify[i]} 2>/dev/null | grep -q ^"Status: install ok installed"$ )then
            echo  "${apps_to_verify[i]} is missing"
            echo  "Please use 'sudo apt-get install ${apps_to_verify[i]}'"
            read -p "Do you want to install it now [y/n] ? (requires sudo) " yn
            case $yn in
                [Yy]* )  sudo apt-get install ${apps_to_verify[i]} ;;
                [Nn]* ) echo -e "${PURPLE}${apps_to_verify[i]} was not installed. leaving build. ${NORMAL} " ; exit 0 ;;
                * ) echo "Please answer y or n.";;
            esac
        fi
        i=$[$i + 1]
    done
}

function setup_workspace()
{
    setup_directories
    verify_installs
}


function build_all()
{
    if [ -z $NO_EXTERNAL ]
    then
        [ $DEFAULT_KERNEL ] && build_uimage
        build_openssl
        build_libnl
        build_crda
    fi

    if [ -z $NO_TI ]
    then
        build_modules
        build_iw
        build_wpa_supplicant
        build_hostapd
        build_calibrator
        build_wlconf
        build_fw_download
        build_scripts_download
        build_uim
        build_bt_firmware
    fi

    [ -z $NO_VERIFY ] && verify_skeleton
}

function setup_and_build()
{
    setup_workspace
}

function main()
{
    [[ "$1" == "-h" || "$1" == "--help"  ]] && usage
    setup_environment
    setup_directories
    read_kernel_version

    case "$1" in
        'init')
            print_highlight " initializing workspace (w/o build) "
            [[  -n "$2" ]] && echo "Using tag $2 " && USE_TAG=$2
            NO_BUILD=1
            setup_workspace
            read_kernel_version #####read kernel version again after init#####
            ;;

        'clean')
            print_highlight " cleaning & building all "
            clean_outputs
            setup_directories
            ;;

        'update')
            clean_outputs
            setup_workspace
            read_kernel_version #####read kernel version again after update#####
            ;;

        'openlink')
            print_highlight " building all (w/o clean) "
            NO_EXTERNAL=1 setup_and_build
            ;;

        #################### Building single components #############################
        'kernel')
            print_highlight " building only Kernel "
            build_uimage
            ;;

        'intree')
            print_highlight " building modules intree"
            build_intree
            ;;

        'kernel_modules')
            print_highlight " building kernel and driver modules"
            build_uimage
            build_modules
            ;;

        'modules')
            print_highlight " building only Driver modules "
            build_modules
            ;;

        'wpa_supplicant')
            print_highlight " building only wpa_supplicant "
            build_wpa_supplicant
            ;;

        'hostapd')
            print_highlight " building only hostapd "
            build_hostapd
            ;;

        'crda')
            print_highlight " building only CRDA "
            build_crda
            ;;

        'libnl')
            print_highlight " building only libnl"
            build_libnl
            ;;

        'iw')
            print_highlight " building only iw"
            build_iw
            ;;

        'openssl')
            print_highlight " building only openssl"
            build_openssl
            ;;

        'scripts')
            print_highlight " Copying scripts "
            build_scripts_download
            ;;

        'utils')
            print_highlight " building only ti-utils "
            build_calibrator
            build_wlconf
            ;;

        'firmware')
            print_highlight " building only firmware"
            build_fw_download
            ;;

        'patch_kernel')
            print_highlight " only patching kernel $2 without performing an actual build!"
            NO_BUILD=1
            patch_kernel
            ;;

        'uim')
            print_highlight " building only uim "
            build_uim
            ;;

        'bt-firmware')
            print_highlight " Only installing bluetooth init scripts "
            build_bt_firmware
            ;;
        ############################################################
        'get_tag')
            get_tag
            exit
            ;;

        'admin_tag')
            admin_tag $2
            ;;

        'check_updates')
            check_for_build_updates
            ;;

        '')
            print_highlight " building all (No clean & no source code update) "
            #clean_outputs
            NO_CLEAN=1 build_all
            ;;

        *)
            echo " "
            echo "**** Unknown parameter - please see usage below **** "
            usage
            ;;
    esac

    [[ -z $NO_BUILD ]] && build_outputs
    [[ -n $INSTALL_NFS ]] && install_outputs
    echo "Wifi Package Build Successful"
}
main $@
