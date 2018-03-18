#!/bin/bash
###############################################################################
# This executable will sign files using IMA private key. It must be run as
# root or under fakeroot.
#
# Author: Dragan Marinkovic <dmarinkovi@sierrawireless.com>
#
# Copyright (c) 2018 Sierra Wireless Inc.
# Use of this work is subject to license.
#
# Example 1: Sign files (legato method)
# =====================================
# fakeroot ./ima-sign.sh \
#             --sign \
#             -p $HOME/.ima/keys/ima/privkey_ima.pem \
#             -d $HOME/tmp/data \
#             --tarball $HOME/tmp/tarball.tar.bz2 \
#             -y legato
#
# Example 1: Sign files (generic method)
# ======================================
# fakeroot ./ima-sign.sh \
#             --sign \
#             -p $HOME/.ima/keys/ima/privkey_ima.pem \
#             -d $HOME/tmp/data \
#             --tarball $HOME/tmp/tarball.tar.bz2
#
###############################################################################

UMASK=022
umask $UMASK

# Version of this executable.
VERSION="0.90"

# Global return types
SWI_OK=0
SWI_ERR=1

# Some other global variables
SWI_FALSE=0
SWI_TRUE=1

# Which tar utility we are going to use? Note that changing
# tar utility here in not ehough, because some options differ.
# One day, if required, we are going to handle multiple choices.
TAR=bsdtar

# Read all options. Remember that:
# ':'  - "must have" option
# '::' - "optional" option
TEMP=`getopt -o svhp:d:t:y: --long sign,version,help,imaprivkey:,rdir:,tarball:,type: -n 'ima-sign' -- "$@"`
if [ $? != 0 ] ; then exit $SWI_ERR ; fi

eval set -- "$TEMP"

# Some influential variables
IMA_SIGN=false
IMA_PRIV_KEY=""
RDIR=""
TARBALL=""
TYPE="default"

#
# Useful methods.
#

function version()
{
    echo ""
    echo " $( basename $0 ) version $VERSION"
    echo ""

    return $SWI_OK
}

# How to use this tool.
function usage()
{

# dump version
    version

    cat << EOF

Usage:
 $0 <commands ...> <parameters ...>

 Commands:

    -s, --sign             Sign files.
    -v, --version          Dump version and exit.
    -h, --help             Print this help page and exit.

 Parameters:

    -p, --imaprivkey       Location of the .ima private key.
    -d, --rdir             Root directory of the files to sign.
    -t, --tarball          Generated tarball name including path
    -y, --type             Type of tarball (e.g. legato).

EOF

    return $SWI_OK
}

#
# Parse options passed to this executable.
#
function parse_options()
{
    while true; do

        case "$1" in

            # Sign files.
            -s | --sign )
                IMA_SIGN=true;
                shift;
                ;;

            # IMA private key.
            -p | --imaprivkey )
                IMA_PRIV_KEY=$2;
                shift 2;
                ;;

            # Files to sign.
            -d | --rdir )
                RDIR=$2;
                shift 2;
                ;;

            # Tarball name (with full path).
            -t | --tarball )
                TARBALL=$2;
                shift 2;
                ;;

            # Tarball type.
            -y | --type )
                TYPE=$2;
                shift 2;
                ;;

            # Version information.
            -v | --version )
                version;
                return $SWI_ERR;
                ;;

            # Help.
            -h | --help )
                usage;
                return $SWI_ERR;
                ;;

            -- )
                shift;
                break;
                ;;

            * )
                echo "Error, exiting."
                return $SWI_ERR;
                ;;
        esac

    done

    return $SWI_OK
}

# Sign files using IMA private key.
function ima_sign_files()
{
    local ret=$SWI_OK

    # We need to run as privileged user to execute this method.
    is_privileged_user
    if [ $? -ne $SWI_TRUE ] ; then
        return $SWI_ERR
    fi


    # Bit of error checking here. If parameters are missing, get out.
    if [ "x$IMA_PRIV_KEY" == "x" -o \
         "x$RDIR"         == "x" -o \
         "x$TARBALL"      == "x" ] ; then

        echo "Missing parameters."
        echo "Parameters dump:"
        echo "    IMA_PRIV_KEY=[$IMA_PRIV_KEY]"
        echo "    RDIR=[$RDIR]"
        echo "    TARBALL=[$TARBALL]"
        echo "    TYPE=[$TYPE]"

        return $SWI_ERR
    fi

    # Sign recursively all files in the destination directory.
    evmctl -r ima_sign --key $IMA_PRIV_KEY $RDIR
    if [ $? -ne $SWI_OK ] ; then
        echo "evmctl failed, files could not be signed."
        return $SWI_ERR
    fi

    # Create tarball.
    cdir=$( pwd )
    if [ "x$TYPE" == "xlegato" ] ; then
        # Legato has a special way of handling tarball creation.
        ( cd $RDIR && \
        find . -print0 | LC_ALL=C sort -z |$TAR --no-recursion --null -T - -cjf - )> $TARBALL
        ret=$?
    elif [ "x$TYPE" == "xdefault" ] ; then
        # Default tarball handling.
        $TAR -c -C $(dirname $RDIR) -jf $TARBALL $(basename $RDIR)
        ret=$?
    else
        echo "Unknown tarball generation method."
        ret=$SWI_ERR
    fi
    cd $cdir

    return $ret
}

# Check the environment we run this executable in.
function check_env()
{

    local temp=""
    local bin_required="bsdtar"

    # We really need getopt
    if [ "x$( which getopt )" == "x" ] ; then
        echo "Please, install GNU getopt."
        return $SWI_ERR
    fi

    # ...and we need evmctl
    if [ "x$( which evmctl )" == "x" ] ; then
        echo "Please, install evmctl."
        return $SWI_ERR
    fi

    # ...and we need bsdtar for IMA to work properly. The only way
    # to know for sure is to execute it and check version string.
    # Otherwise, someone may think it's clever to make bsdtar
    # softlink to GNU tar, and work around the problem of not
    # having bsdtar.
    temp=$( $TAR --version 2>&1 | awk '{ print $1}' | head -1 | grep "$bin_required" )
    if [ "x$temp" == "x" ] ; then
        echo "error: $bin_required not found, please install it."
        return $SWI_ERR
    fi

    return $SWI_OK
}

# Check if we have elevated privileges.
function is_privileged_user()
{
    # Must be root to run it on host.
    if [ $( id -u ) -ne 0 ] ; then
        echo "  You must run this command as privileged user (e.g. root), exiting."
        return $SWI_FALSE
    fi

    return $SWI_TRUE
}

function main()
{

    # Check the environment
    check_env
    if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi

    # parse passed options
    parse_options "$@"
    if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi

    if [ "x$IMA_SIGN" == "xtrue" ] ; then
        ima_sign_files
        if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi
    fi

    return $SWI_OK
}

# This is where it all begins
main "$@"
