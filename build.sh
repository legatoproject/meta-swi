#!/bin/bash
#
# Copyright (c) 2011-2012 Wind River Systems, Inc.
#

# Let bitbake use the following env-vars as if they were pre-set bitbake ones.
# (BBLAYERS is explicitly blocked from this within OE-Core itself, though...)
export BB_ENV_EXTRAWHITE="http_proxy MACHINE DISTRO DL_DIR"

IFS='
    '

PATH=/usr/local/bin:/bin:/usr/bin
export PATH


UMASK=022
umask $UMASK

scriptdir=$(cd $(dirname ${0}); pwd)
WS="$scriptdir/../poky"

ALL_ARGS="$*"

# Some useful global variables
SWI_OK=0
SWI_ERR=1

usage()
{
    cat << EOF
Usage:
$0 <options ...>

  Global:
    -p <poky_dir>
    -o <meta-openembedded dir>
    -l <SWI meta layer>
    -x <linux repo directory>
    -m <SWI machine type>
    -b <build_dir>
    -t <number of bitbake tasks>
    -j <number of make threads>
    -r (enable preempt-rt kernel <Test-only. Not supported>)
    -g (enable Legato setup and build Legato images)
    -a (pass extra options for recipes, key=value separated by ::)
    -K <kernel provider>
    -e (enable build recovery image or normal image)
    -i <ima-config-file> (enable IMA build, pass full path to ima.conf as a parameter)
    -B Pass flags directly to bitbake (e.g. -vvv for verbose build)
    -E Enable extended SWI image (add additional developer packages)

  Machine swi-mdmXXXX:
    -q (enable Qualcomm Proprietary bin)
    -s (enable Qualcomm Proprietary source)
    -w <Qualcomm source directory (apps_proc)>
    -v <version of Qualcomm sources>
    -F <path to ar_yocto-cwe.tar.bz2>
    -M (enable mangoh meta layer)
    -Q (building for Qemu)

  Task control:
    -c (enable command line mode)
    -d (build the full debug image)
    -k (build the toolchain)
EOF
}

usage_and_exit()
{
    usage
    exit $1
}

if [ $# = 0 ]; then
    usage_and_exit 1
fi

# Default options
BD="$scriptdir/../build"
MACH=swi-mdm9x28
DEBUG=false
TASKS=4
THREADS=4
CMD_LINE=false
TOOLCHAIN=false
ENABLE_PROPRIETARY=false
ENABLE_PROPRIETARY_SRC=false
ENABLE_ICECC=false
ENABLE_EXT_SWI_IMG=false
ENABLE_LEGATO=false
ENABLE_META_MANGOH=false
DISTRO=poky-swi
KERNEL_PROVIDER=
X_OPTS=
PROD=
ENABLE_RECOVERY=
QEMU=false
ENABLE_IMA=false
IMA_CONFIG=""
BB_FLAGS=""

while getopts ":p:o:b:l:x:m:t:j:w:v:a:F:P:i:B:MecdrqsgkhEQ" arg
do
    case $arg in
    p)
        WS=$(readlink -f $OPTARG)
        echo "Poky dir: $WS"
        ;;
    o)
        OE=$(readlink -f $OPTARG)
        echo "OE meta: $OE"
        ;;
    b)
        BD=$(readlink -f $OPTARG)
        echo "Build dir: $BD"
        ;;
    l)
        SWI=$(readlink -f $OPTARG)
        echo "SWI meta dir: $SWI"
        ;;
    x)
        LINUXDIR=$(readlink -f $OPTARG)
        echo "Linux repo dir: $LINUXDIR"
        ;;
    m)
        MACH=$OPTARG
        echo "SWI machine: $MACH"
        ;;
    d)
        DEBUG=true
        echo "Enable more packages for debugging"
        ;;
    t)
        TASKS=$OPTARG
        echo "Number of bitbake tasks $TASKS"
        ;;
    j)
        THREADS=$OPTARG
        echo "Number of make threads $THREADS"
        ;;
    a)
        X_OPTS="$X_OPTS $OPTARG"
        echo "Extra options added -  $OPTARG"
        ;;
    K)
        KERNEL_PROVIDER="$OPTARG"
        echo "Kernel provider: $KERNEL_PROVIDER"
        ;;
    e)
        ENABLE_RECOVERY="true"
        echo "Enable recovery image: $ENABLE_RECOVERY"
        ;;
    c)  CMD_LINE=true
        echo "Enable command line mode"
        ;;
    q)  ENABLE_PROPRIETARY=true
        echo "Enable Qualcomm Proprietary bin"
        ;;
    s)  ENABLE_PROPRIETARY_SRC=true
        echo "Enable Qualcomm Proprietary source - overrides binary option"
        ;;
    w)
        WK=$(readlink -f $OPTARG)
        [ -n "$WK" ] || echo "warning: -w $OPTARG (for WK variable) doesn't resolve"
        ;;
    v)
        FW_VERSION=$OPTARG
        echo "FW Version: $FW_VERSION"
        ;;
    g)
        ENABLE_LEGATO="true"
        echo "With Legato"
        ;;
    k)  TOOLCHAIN=true
        echo "Build toolchain"
        ;;
    h)  ENABLE_ICECC=true
        echo "Build using icecc"
        ;;
    E)  ENABLE_EXT_SWI_IMG=true
        echo "Sierra Wireless extended packages are enabled"
        ;;
    F)  FIRMWARE_PATH=$(readlink -f $OPTARG)
        echo "Use FIRWARE_PATH=${FIRMWARE_PATH} to fetch ar_yocto-cwe.tar.bz2 binary"
        ;;
    M)  ENABLE_META_MANGOH=true
        echo "With mangOH"
        ;;
    P)
        PROD=$OPTARG
        echo "SWI product: $PROD"
        ;;
    Q)  QEMU=true
        echo "Building for QEMU"
        ;;
    i)  ENABLE_IMA=true
        IMA_CONFIG=$OPTARG
        echo "IMA is enabled."
        ;;
    B)  BB_FLAGS=$OPTARG
        echo "bitbake flags: [$BB_FLAGS]"
        ;;
    ?)
        echo "$0: invalid option -$OPTARG" 1>&2
        usage_and_exit 1
        ;;
    esac
done

. ${WS}/oe-init-build-env $BD

## Check: bash

# Make sure that bash is set as default or build is not guaranteed to work
if [[ "$(basename $(readlink -f /bin/sh))" != "bash" ]]; then
    echo "Error: bash is not set as default provider for /bin/sh"
    echo "       build is not guaranteed to work, aborting"
    exit 1
fi

## Conf: bblayers.conf
declare -a LAYERS

enable_layer()
{
    local LAYER_NAME=$1
    local LAYER_PATH=$2
    local PREVIOUS_LAYER=$3

    if [ -z "$PREVIOUS_LAYER" ]; then
        PREVIOUS_LAYER='meta-yocto-bsp'
    fi

    echo "+ layer: $LAYER_NAME"

    LAYERS+=("$LAYER_PATH")

    grep -E "/$LAYER_NAME " $BD/conf/bblayers.conf > /dev/null
    if [ $? != 0 ]; then
        echo "         -> $LAYER_PATH"
        sed -e '/'"$PREVIOUS_LAYER"'/a\  '"$LAYER_PATH"' \\' -i $BD/conf/bblayers.conf
    fi
}

case $MACH in
    swi-virt-* )
        enable_layer "meta-swi-virt" "$SWI/meta-swi-virt"
        ;;
    swi-mdm9* )
        # Enable the common meta-swi-mdm9xxx layer
        enable_layer "meta-swi/meta-swi-mdm9xxx" "$SWI/meta-swi-mdm9xxx"

        # Enable the meta-swi-mdmNNNN layer
        enable_layer "meta-swi/meta-$MACH" "$SWI/meta-$MACH" "meta-swi-mdm9xxx"

        # Enable the meta-swi-mdmNNNN-PROD layer, if it exists
        if [ -n "$PROD" ] && [ -e "$SWI/meta-${MACH}-${PROD}" ]; then
            enable_layer "meta-swi/meta-$MACH-$PROD" "$SWI/meta-$MACH-$PROD" "meta-$MACH"
        fi

        if [ $ENABLE_PROPRIETARY_SRC = true ] || [ $ENABLE_PROPRIETARY = true ]; then
            # Distro to poky-swi-ext to change SDKPATH
            DISTRO="poky-swi-ext"
        fi
        ;;
esac

# Enable the meta-swi layer
enable_layer "meta-swi/common" "$SWI/common"

# Enable the meta-oe layer
enable_layer "meta-oe" "$OE/meta-oe"

# Enable the meta-networking layer
enable_layer "meta-networking" "$OE/meta-networking"

# Enable the meta-python layer
enable_layer "meta-python" "$OE/meta-python"

# Enable proprietary layers: common
if [ $ENABLE_PROPRIETARY_SRC = true ] || [ $ENABLE_PROPRIETARY = true ]; then
    enable_layer "meta-swi-extras/common" "$scriptdir/../meta-swi-extras/common" "meta-$MACH"

    enable_layer "meta-swi-extras/meta-$MACH" "$scriptdir/../meta-swi-extras/meta-$MACH" "meta-$MACH"
fi

# Enable meta-mangoh layer
if [ $ENABLE_META_MANGOH = true ]; then
    enable_layer "meta-mangoh" "$scriptdir/../meta-mangoh"
fi

# Enable proprietary layers: from sources
if [ $ENABLE_PROPRIETARY_SRC = true ]; then
    # Check that we have a source workspace to point to
    WK=${WK:-$WORKSPACE}
    WORKSPACE=${WK:?"Not set - must point to apps_proc of firmware build"}

    if [ ! -d ${WORKSPACE}/qmi ]; then
        echo WORKSPACE \(${WORKSPACE}\) appears not to be a valid source location
        echo WORKSPACE must point to apps_proc of firmware build
        exit 1
    fi

    echo "Workspace dir: $WORKSPACE"
    export WORKSPACE

    if [ -n "$FW_VERSION" ]; then
        echo "Workspace version: $FW_VERSION"
        export FW_VERSION
    fi

    # Add common mdm9xxx source layer
    enable_layer "meta-swi-extras/meta-swi-mdm9xxx-src" "$scriptdir/../meta-swi-extras/meta-swi-mdm9xxx-src" "meta-swi-extras\/common"

    # Add machine-specific source layer
    enable_layer "meta-swi-extras/meta-$MACH-src" "$scriptdir/../meta-swi-extras/meta-$MACH-src" "meta-swi-mdm9xxx-src"

    # Add product-specific source layer
    if [ -n "$PROD" ] && [ -e "$scriptdir/../meta-swi-extras/meta-$MACH-$PROD-src" ]; then
        enable_layer "meta-swi-extras/meta-$MACH-$PROD-src" \
            "$scriptdir/../meta-swi-extras/meta-$MACH-$PROD-src" \
            "meta-$MACH-src"
    fi

    copy_qmi_api() {
        cp -f $WORKSPACE/../modem_proc/sierra/src/dx/src/common/* $WORKSPACE/sierra/dx/common
        if [ $? != 0 ]; then
            echo "Unable to copy dx common files from modem_proc"
            exit 1
        fi
        cp -f $WORKSPACE/../modem_proc/sierra/src/dx/api/common/* $WORKSPACE/sierra/dx/common
        if [ $? != 0 ]; then
            echo "Unable to copy dx common API files from modem_proc"
            exit 1
        fi
        # We have to copy the qapi files from the modem dir
        cp -f $WORKSPACE/../modem_proc/sierra/src/qapi/src/common/* $WORKSPACE/sierra/qapi/common
        if [ $? != 0 ]; then
            echo "Unable to copy qapi common files from modem_proc"
            exit 1
        fi
        # Provice common qcsi files as a link to common qapi files
        rm -rf $WORKSPACE/sierra/qcsi/common && ( cd $WORKSPACE/sierra/qcsi && ln -s ../qapi/common common )
        if [ $? != 0 ]; then
            echo "Unable to provide qcsi common files from modem_proc"
            exit 1
        fi
        # We have to copy the NV files from the modem dir
        cp -f $WORKSPACE/../modem_proc/sierra/src/nv/src/common/* $WORKSPACE/sierra/nv/common
        if [ $? != 0 ]; then
            echo "Unable to copy NV common files from modem_proc"
            exit 1
        fi
        cp -f $WORKSPACE/../modem_proc/sierra/src/nv/api/common/* $WORKSPACE/sierra/nv/common
        if [ $? != 0 ]; then
            echo "Unable to copy NV API files from modem_proc"
            exit 1
        fi
    }

    if [[ "$MACH" == "swi-mdm9x15" ]]; then
        # We have to copy the dx files from the modem dir
        copy_qmi_api
    fi
fi

# Enable proprietary layers: from binaries
if [ $ENABLE_PROPRIETARY = true ]; then
    # Add common mdm9xxx binary layer
    enable_layer "meta-swi-extras/meta-swi-mdm9xxx-bin" "$scriptdir/../meta-swi-extras/meta-swi-mdm9xxx-bin" "meta-$MACH"

    # Add machine-specific binary layer
    enable_layer "meta-swi-extras/meta-$MACH-bin" "$scriptdir/../meta-swi-extras/meta-$MACH-bin" "meta-swi-mdm9xxx-bin"

    # Add product-specific source layer
    if [ -n "$PROD" ] && [ -e "$scriptdir/../meta-swi-extras/meta-$MACH-$PROD-bin" ]; then
        enable_layer "meta-swi-extras/meta-$MACH-$PROD-bin" \
            "$scriptdir/../meta-swi-extras/meta-$MACH-$PROD-bin" \
            "meta-$MACH-bin"
    fi
fi

## Conf: local.conf

set_option() {
    opt_name=$1
    opt_val=$2

    if grep "$opt_name =" $BD/conf/local.conf > /dev/null; then
        # Update entry
        echo "Updating $opt_name to $opt_val"
        sed -e "s/$opt_name = \".*//g" -i $BD/conf/local.conf
        echo "$opt_name = \"$opt_val\"" >> $BD/conf/local.conf
    else
        # Append
        echo "Adding option $opt_name with value $opt_val"
        echo "$opt_name = \"$opt_val\"" >> $BD/conf/local.conf
    fi
}

check_machine_name() {
    local machine=$1

    for layer in ${LAYERS[@]}; do
        machine_file=$(find $layer -name "${machine}.conf" -print)
        if [ -n "$machine_file" ]; then
            return 0
        fi
    done

    return 1
}

set_machine() {
    local machine=$1

    # Check if that machine is declared in the layers
    if ! check_machine_name $machine; then
        return 1
    fi

    if [ $QEMU = true ]; then
        MACH_LOCAL_CONF="${machine}-qemu"
    else
        MACH_LOCAL_CONF=$machine
    fi

    echo "Yocto machine: ${MACH_LOCAL_CONF}"
    sed -e 's:^\(MACHINE\).*:\1 = \"'${MACH_LOCAL_CONF}'\":' -i $BD/conf/local.conf
}

# Set IMA options. If IMA build is required, we need to add number
# of options to our global, static configuration file.
set_ima()
{
    local ret=$SWI_OK

    # Always set this option, because it may have been set to something
    # else previously. This will enable or disable IMA build.
    set_option "IMA_BUILD" $ENABLE_IMA

    if [ "$ENABLE_IMA" == "true" ] ; then

        # IMA build should be enabled, make sure we know what the IMA config is.
        # Variable names here must match variable names in ima.conf .
        # We are adding these to global conf file, because this is
        # common information, and if we do not do it here, we would need
        # to source $IMA_CONFIG on multiple places, which would slow
        # down the build.

        if [ -f $IMA_CONFIG ] ; then

            echo "IMA config is specified, setting IMA options..."

            # Get variables from IMA configuration file.
            source $IMA_CONFIG

            # And write the ones we need to global configuration file.
            set_option "IMA_CONFIG" $IMA_CONFIG
            set_option "IMA_LOCAL_CA_X509" $IMA_LOCAL_CA_X509
            set_option "IMA_PRIV_KEY" $IMA_PRIV_KEY
            set_option "IMA_PUB_CERT" $IMA_PUB_CERT
            set_option "IMA_KERNEL_CMDLINE_OPTIONS" "$IMA_KERNEL_CMDLINE_OPTIONS"

            # Now, set some variables Legato build may need. Legato likes to use
            # different set of variables. This is perfectly fine, because we want
            # to decouple system from Legato, and use indipendently written
            # interfaces.

            # Set this to 1 if ENABLE_IMA=true, 0 otherwise.
            set_option "ENABLE_IMA" 1
            set_option "IMA_PUBLIC_CERT" $IMA_PUBLIC_CERT
            set_option "IMA_PRIVATE_KEY" $IMA_PRIVATE_KEY
        else
            echo "error: IMA is enabled, but IMA config file [$IMA_CONFIG] does not exist."
            ret=$SWI_ERR
        fi
    else
            # Unset everything. If not unset, some of these variables
            # could create problems later on in the build, because
            # they may get out of sync.
            set_option "IMA_CONFIG"
            set_option "IMA_LOCAL_CA_X509"
            set_option "IMA_PRIV_KEY"
            set_option "IMA_PUB_CERT"
            set_option "IMA_KERNEL_CMDLINE_OPTIONS"
            set_option "ENABLE_IMA" 0
            set_option "IMA_PUBLIC_CERT"
            set_option "IMA_PRIVATE_KEY"
    fi

    return $ret
}

# Tune local.conf file
if [ -n "${PROD}" ]; then
    if [ -n "$ENABLE_RECOVERY" ]; then
        if ! set_machine "${MACH}-${PROD}-rcy"; then
            # If <MACH>-<PROD> is not available, fallback to <MACH>
            set_machine "${MACH}-rcy"
        fi
    elif ! set_machine "${MACH}-${PROD}"; then
        # If <MACH>-<PROD> is not available, fallback to <MACH>
        set_machine "${MACH}"
    fi
else
    set_machine "${MACH}"
fi

grep -E "SOURCE_MIRROR_URL" $BD/conf/local.conf > /dev/null
if [ $? != 0 ]; then
        sed -e '/^#DL_DIR/a\SOURCE_MIRROR_URL ?= \"file\:\/\/'"$scriptdir"'/../downloads\"\nINHERIT += \"own-mirrors\"\nBB_GENERATE_MIRROR_TARBALLS = \"1\"\nBB_NO_NETWORK = \"0\"\nWORKSPACE = \"'"${WORKSPACE}"'\"\nLINUX_REPO_DIR = \"'"${LINUXDIR}"'\"\nDISTRO = \"'"${DISTRO}"'\"' -i $BD/conf/local.conf
fi
sed -e 's:^#\(BB_NUMBER_THREADS\).*:\1 = \"'"$TASKS"'\":' -i $BD/conf/local.conf
sed -e 's:^#\(PARALLEL_MAKE\).*:\1 = \"-j '"$THREADS"'\":' -i $BD/conf/local.conf

set_option "LEGATO_BUILD" $ENABLE_LEGATO

# Set all IMA related build options
set_ima
if [ $? != $SWI_OK ]; then exit 1 ; fi

if [ -n "$FW_VERSION" ]; then
    FW_VERSION_ENTRY=$(grep "FW_VERSION =" $BD/conf/local.conf)
    if [ $? != 0 ]; then
        # Append
        sed -e '/^WORKSPACE/a\FW_VERSION = \"'"${FW_VERSION}"'\"\n' -i $BD/conf/local.conf
    else
        CURRENT_FW_VERSION=$(echo $FW_VERSION_ENTRY | sed -e 's/FW_VERSION = \"\(.*\)\"/\1/g')
        if [[ "$FW_VERSION" != "$CURRENT_FW_VERSION" ]]; then
            # Update entry
            echo "Updating FW_VERSION from '${CURRENT_FW_VERSION}' to '${FW_VERSION}'"
            sed -e 's/FW_VERSION = \".*\"/FW_VERSION = \"'"${FW_VERSION}"'\"/g' -i $BD/conf/local.conf
        else
            echo "Keeping FW_VERSION '${FW_VERSION}'"
        fi
    fi
fi

set_option "ROOTFS_VERSION" $ROOTFS_VERSION

# Add or update extra options
if [ -n "$X_OPTS" ]
then
    EXTRA_OPTS=$(echo $X_OPTS | sed -e "s/\:\:/ /g")
    for OPT in $EXTRA_OPTS
    do
        opt_name=$(echo $OPT | cut -d"=" -f1)
        opt_val=$(echo $OPT | cut -d"=" -f2-)

        set_option $opt_name $opt_val
    done
fi

# Kernel provider
if [ -z "$KERNEL_PROVIDER" ]; then
    case $MACH in
        swi-mdm9x15 )
            KERNEL_PROVIDER="linux-yocto"
            ;;
        swi-mdm9* )
            KERNEL_PROVIDER="linux-quic"
            ;;
        * )
            KERNEL_PROVIDER="linux-yocto"
            ;;
    esac
fi

grep -E "PREFERRED_PROVIDER_virtual\/kernel" $BD/conf/local.conf > /dev/null
if [ $? != 0 ]; then
    echo "PREFERRED_PROVIDER_virtual/kernel = \"${KERNEL_PROVIDER}\"" >> $BD/conf/local.conf
else
    sed -e 's:^\(PREFERRED_PROVIDER_virtual\/kernel\).*:\1 = \"'${KERNEL_PROVIDER}'\":' -i $BD/conf/local.conf
fi

# IceCC
if [ $ENABLE_ICECC = true ]; then
    if ! grep icecc $BD/conf/local.conf > /dev/null; then
        echo 'INHERIT += "icecc"' >> $BD/conf/local.conf
        echo 'ICECC_PARALLEL_MAKE = "-j 20"' >> $BD/conf/local.conf
        echo 'ICECC_USER_PACKAGE_BL = "ncurses e2fsprogs libx11 gmp libcap perl busybox lk libgpg-error libarchive"' >> $BD/conf/local.conf
    fi
fi

# SWI extended packages.
set_option "EXT_SWI_IMG" $ENABLE_EXT_SWI_IMG
if [ $ENABLE_EXT_SWI_IMG = true ] ; then
    # Not supported for deployment for various reasons, warn the users.
    echo "warning: You are building debug image not intended for deployment. Use it at your own risk."
fi

# Initramfs
case $MACH in
    swi-mdm* )
        set_option 'INITRAMFS_IMAGE_BUNDLE' '1'
        if test x$ENABLE_RECOVERY = "xtrue"; then
            set_option 'INITRAMFS_IMAGE' "mdm-image-recovery"
        else
            set_option 'INITRAMFS_IMAGE' "${MACH#swi-}-image-initramfs"
        fi
        ;;
esac

# Firmware Path
set_option 'FIRMWARE_PATH' "${FIRMWARE_PATH}"

# Remove GNUTLS
set_option 'PACKAGECONFIG_remove' "gnutls"

cd $BD

# Command line
if [ $CMD_LINE = true ]; then
    /bin/bash
    exit $?
fi

# Toolchain
if [ $TOOLCHAIN = true ]; then
    case $MACH in
       swi-mdm* )
           bitbake ${BB_FLAGS} meta-toolchain-swi-ext
           ;;
       * )
           bitbake ${BB_FLAGS} meta-toolchain-swi
           ;;
    esac
    exit $?
fi

# Images
echo -n "Build image of "
if [ $DEBUG = true ]; then
    echo "dev rootfs (for $MACH)."
    sed -e 's:^\(PACKAGE_CLASSES\).*:\1 = \"package_rpm\":' -i $BD/conf/local.conf
    case $MACH in
        swi-mdm* )
            bitbake ${BB_FLAGS} ${MACH#swi-}-image-dev
            ;;
        swi-virt* )
            bitbake ${BB_FLAGS} swi-virt-image-dev
            ;;
        * )
            bitbake ${BB_FLAGS} core-image-dev
            ;;
    esac
    exit $?
else
    echo "minimal rootfs (for $MACH)."
    sed -e 's:^\(PACKAGE_CLASSES\).*:\1 = \"package_ipk\":' -i $BD/conf/local.conf
    case $MACH in
        swi-mdm* )
            if test x$ENABLE_RECOVERY = "xtrue"; then
                bitbake ${BB_FLAGS} mdm-image-recovery
            else
                bitbake ${BB_FLAGS} ${MACH#swi-}-image-minimal
            fi
            ;;
        swi-virt* )
            bitbake ${BB_FLAGS} swi-virt-image-minimal
            ;;
        * )
            bitbake ${BB_FLAGS} core-image-minimal
            ;;
    esac
    exit $?
fi

