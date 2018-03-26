#!/bin/bash
###############################################################################
# This executable will generate various keys and certificates based on various
# input options.
#
# Author: Dragan Marinkovic <dmarinkovi@sierrawireless.com>
#
# Copyright (C) 2018 Sierra Wireless Inc.
# Use of this work is subject to license.
#
# Example 1: Generate all keys
# ============================
#
# In this example, system will generate all keys required. In order to
# generate all keys, ".system" (ima-local-ca.genkey) and ".ima"
# (ima.genkey) configuration files must exist.
#
#  ./ima-gen-keys.sh -a -c ~/tmp/config/ima-local-ca.genkey \
#                       -m ~/tmp/config/ima.genkey \
#                       -n ~/tmp/keys/system/ima-local-ca.priv \
#                       -o ~/tmp/keys/system/ima-local-ca.x509 \
#                       -p ~/tmp/keys/ima/privkey_ima.pem \
#                       -q ~/tmp/keys/ima/csr_ima.pem
#
# Example 2: Sign ".ima" request for signing
# ==========================================
# ./ima-gen-keys.sh -g -q ~/tmp/keys/ima/csr_ima.pem \
#                      -m ~/tmp/config/ima.genkey \
#                      -n ~/tmp/keys/system/ima-local-ca.priv \
#                      -o ~/tmp/keys/system/ima-local-ca.x509 \
#                      -r ~/tmp/keys/ima/x509_ima.der
#
###############################################################################

UMASK=022
umask $UMASK

# Version of this executable.
VERSION="0.91"

# Global return types
SWI_OK=0
SWI_ERR=1

# Read all options. Remember that:
# ':'  - "must have" option
# '::' - "optional" option
TEMP=`getopt -o asigvhc:m:n:o:p:q:r:e: --long allkeys,systemkeys,imakeys,signimareq,version,help,systemconf:,imaconf:,systemprivkey:,systemcert:,imaprivkey:,imareqsigncert:,imacert:,expiration: -n 'ima-gen-keys' -- "$@"`
if [ $? != 0 ] ; then exit $SWI_ERR ; fi

eval set -- "$TEMP"

# Some influential variables
GEN_ALL_KEYS=false
GEN_IMA_KEYS=false
GEN_SYSTEM_KEYS=false
SIGN_IMA_REQ=false
SYSTEM_CONF=""
IMA_CONF=""
SYSTEM_PRIV_KEY=""
SYSTEM_PUB_CERT=""
SYSTEM_PUB_CERT_PEM=""
IMA_PRIV_KEY=""
IMA_REQSIGN_CERT=""
IMA_PUB_CERT=""
KEY_EXP_DAYS=365

#
# Useful methods.
#

# Dump version of this executable.
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
 $( basename $0 ) <commands ...> <parameters ...>

 Key information:
    .system private key   Used to to sign .ima x509 public key certificate
                          signing request. The output of signing will be
                          binary (DER) public certificate, which will be loaded
                          to .ima keyring at run-time. Normally, this should
                          never be exposed to anyone, and should be kept at
                          the very safe place.
    .system x509 cert     It will be embedded into the kernel image at build
                          time.
    .ima private key      Used to sign binaries which would be running on
                          IMA protected system.
    .ima x509 cert        Needs to be loaded into .ima keyring at runtime.
                          Without it, signed binaries would not be able to
                          run on IMA protected system. It will be verified
                          by .system x509 cert at runtime.
    .ima sign req         .ima signing request. It needs to be signed by
                          .system private key. Once signed, it will become
                          .ima x509 cert.

 Commands:

    -a, --allkeys          Generate all keys. The following will be generated:
                               .system private key, .system x509 public key
                               certificate, .ima private key and .ima x509 public
                               key certificate signing request.
    -s, --systemkeys       Generate .system key pair.
    -i, --imakeys          Generate .ima key pair.
    -g, --signimareq       Sign IMA public key certificate signing request.
    -v, --version          Dump version and exit.
    -h, --help             Print this help page and exit.

 Parameters:

    -c, --systemconf       Configuration file for .system keypair.
    -m, --imaconf          Configuration file for .ima keypair.
    -n, --systemprivkey    Location of the .system private key.
    -o, --systemcert       Location of the .system public certificate.
    -p, --imaprivkey       Location of the .ima private key.
    -q, --imareqsigncert   Location of the .ima public key certificate signing
                           request.
    -r, --imacert          Location of the .ima public certificate.
    -e, --expiration       Certificate expiration in days.


Some of the options may be specified together. For example:
    $( basename $0 ) -si
is equivalent to:
    $( basename $0 ) -a
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

            # Generate:
            #   .system private key and x509 public key certificate.
            #   .ima private key and X509 public key certificate
            #       signing request.
            -a | --allkeys )
                GEN_ALL_KEYS=true;
                shift;
                ;;

            # Generate .system private key and x509 public key certificate.
            -s | --systemkeys )
                GEN_SYSTEM_KEYS=true;
                shift;
                ;;

            # Generate .ima private key and X509 public key certificate
            # signing request.
            -i | --imakeys )
                GEN_IMA_KEYS=true;
                shift;
                ;;

            # Sign .ima x509 public key certificate signing request with local IMA CA
            # private key.
            -g | --signimareq )
                SIGN_IMA_REQ=true;
                shift;
                ;;

            # The name of the .system key generation configuration file.
            -c | --systemconf )
                SYSTEM_CONF=$2;
                shift 2;
                ;;

            # The name of the .ima key generation configuration file.
            -m | --imaconf )
                IMA_CONF=$2;
                shift 2;
                ;;

            # Location of the .system private key.
            -n | --systemprivkey )
                SYSTEM_PRIV_KEY=$2;
                shift 2;
                ;;

            # Location of the .system public certificate.
            -o | --systemcert )
                SYSTEM_PUB_CERT=$2;
                SYSTEM_PUB_CERT_PEM=$(get_system_cert_pem $SYSTEM_PUB_CERT)
                shift 2;
                ;;

            # Location of the .ima private key.
            -p | --imaprivkey )
                IMA_PRIV_KEY=$2;
                shift 2;
                ;;

            # Location of the .ima key signing request cert.
            -q | --imareqsigncert )
                IMA_REQSIGN_CERT=$2;
                shift 2;
                ;;

            -r | --imacert )
                IMA_PUB_CERT=$2;
                shift 2;
                ;;

            # key expiration (days)
            -e | --expiration )
                KEY_EXP_DAYS=$2;
                shift 2;
                ;;

            # Executable version.
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

# Generate all keys required by the system.
# If all goes well, this method will return SWI_OK, SWI_ERR otherwise.
function create_all_keys()
{
    # Bit of error checking here. If parameters are missing, get out.
    if [ "x$SYSTEM_CONF"         == "x" -o \
         "x$IMA_CONF"            == "x" -o \
         "x$SYSTEM_PRIV_KEY"     == "x" -o \
         "x$SYSTEM_PUB_CERT"     == "x" -o \
         "x$SYSTEM_PUB_CERT_PEM" == "x" -o \
         "x$IMA_PRIV_KEY"        == "x" -o \
         "x$IMA_REQSIGN_CERT"    == "x" ] ; then

        echo "Missing parameters."
        echo "Parameters dump:"
        echo "    SYSTEM_CONF=[$SYSTEM_CONF]"
        echo "    IMA_CONF=[$IMA_CONF]"
        echo "    SYSTEM_PRIV_KEY=[$SYSTEM_PRIV_KEY]"
        echo "    SYSTEM_PUB_CERT=[$SYSTEM_PUB_CERT]"
        echo "    SYSTEM_PUB_CERT_PEM=[$SYSTEM_PUB_CERT_PEM]"
        echo "    IMA_PRIV_KEY=[$IMA_PRIV_KEY]"
        echo "    IMA_REQSIGN_CERT=[$IMA_REQSIGN_CERT]"

        return $SWI_ERR
    fi

    # Check for ".system" configuration file.
    if [ ! -f $SYSTEM_CONF ] ; then
        echo "'.system' configuration file does not exist."
        return $SWI_ERR
    fi

    # Check for ".ima" configuration file.
    if [ ! -f $IMA_CONF ] ; then
        echo "'.ima' configuration file does not exist."
        return $SWI_ERR
    fi

    # Create directory where ".system" private key will be stored.
    mkdir -p $( dirname $SYSTEM_PRIV_KEY )
    if [ $? -ne $SWI_OK ] ; then
        echo ".system private key file directory could not be created."
        return $SWI_ERR
    fi

    # Create directory where ".system" public certificate will be stored.
    mkdir -p $( dirname $SYSTEM_PUB_CERT )
    if [ $? -ne $SWI_OK ] ; then
        echo ".system public certificate directory could not be created."
        return $SWI_ERR
    fi

    # Create directory where ".system" public certificate will be stored.
    mkdir -p $( dirname $SYSTEM_PUB_CERT_PEM )
    if [ $? -ne $SWI_OK ] ; then
        echo ".system public certificate (PEM) directory could not be created."
        return $SWI_ERR
    fi

    # Create directory where ".ima" private key will be stored.
    mkdir -p $( dirname $IMA_PRIV_KEY )
    if [ $? -ne $SWI_OK ] ; then
        echo ".ima private key directory could not be created."
        return $SWI_ERR
    fi

    # Create directory where ".ima" request for certificate signing request
    # will be stored.
    mkdir -p $( dirname $IMA_REQSIGN_CERT )
    if [ $? -ne $SWI_OK ] ; then
        echo ".ima public key certificate signing request directory could not be created."
        return $SWI_ERR
    fi

    # All is good, we can create keys now.

    # Create ".system" keys
    create_system_keys
    if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi

    # Create ".ima" keys
    create_ima_keys
    if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi

    return $SWI_OK
}

# Create ".system" key pair
function create_system_keys()
{

    # Bit of error checking. If parameters are missing, get out.
    if [ "x$SYSTEM_CONF"         == "x" -o \
         "x$SYSTEM_PRIV_KEY"     == "x" -o \
         "x$SYSTEM_PUB_CERT"     == "x" -o \
         "x$SYSTEM_PUB_CERT_PEM" == "x" ] ; then

        echo "Missing parameters."
        echo "Parameters dump:"
        echo "    SYSTEM_CONF=[$SYSTEM_CONF]"
        echo "    SYSTEM_PRIV_KEY=[$SYSTEM_PRIV_KEY]"
        echo "    SYSTEM_PUB_CERT=[$SYSTEM_PUB_CERT]"
        echo "    SYSTEM_PUB_CERT_PEM=[$SYSTEM_PUB_CERT_PEM]"

        return $SWI_ERR
    fi

    # Generate private/public ".system" pair.
    openssl req -new -x509 -utf8 -sha1 -days $KEY_EXP_DAYS -batch -nodes \
                -config $SYSTEM_CONF \
                -outform DER \
                -out $SYSTEM_PUB_CERT \
                -keyout $SYSTEM_PRIV_KEY
    if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi

    # Convert DER to PEM
    openssl x509 -inform DER -in $SYSTEM_PUB_CERT -out $SYSTEM_PUB_CERT_PEM
    if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi

    return $SWI_OK
}

# Create ".ima" key pair. Public certificate will not be signed.
function create_ima_keys()
{

    # Bit of error checking. If parameters are missing, get out.
    if [ "x$IMA_CONF"         == "x" -o \
         "x$IMA_REQSIGN_CERT" == "x" -o \
         "x$IMA_PRIV_KEY"     == "x" ] ; then

        echo "Missing parameters."
        echo "Parameters dump:"
        echo "    IMA_CONF=[$IMA_CONF]"
        echo "    IMA_REQSIGN_CERT=[$IMA_REQSIGN_CERT]"
        echo "    IMA_PRIV_KEY=[$IMA_PRIV_KEY]"

        return $SWI_ERR
    fi

    # Generate private key and X509 public key certificate signing request
    openssl req -new -nodes -utf8 -sha1 -days $KEY_EXP_DAYS -batch \
            -config $IMA_CONF \
            -out $IMA_REQSIGN_CERT \
            -keyout $IMA_PRIV_KEY
    if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi

    return $SWI_OK
}

# Sign ".ima" public key request for signing
function sign_ima_req()
{

    # Bit of error checking here. If parameters are missing, get out.
    if [ "x$IMA_REQSIGN_CERT"    == "x" -o \
         "x$IMA_CONF"            == "x" -o \
         "x$SYSTEM_PUB_CERT_PEM" == "x" -o \
         "x$SYSTEM_PRIV_KEY"     == "x" -o \
         "x$IMA_PUB_CERT"        == "x" ] ; then

        echo "Missing parameters."
        echo "Parameters dump:"
        echo "    IMA_REQSIGN_CERT=[$IMA_REQSIGN_CERT]"
        echo "    IMA_CONF=[$IMA_CONF]"
        echo "    SYSTEM_PUB_CERT_PEM=[$SYSTEM_PUB_CERT_PEM]"
        echo "    SYSTEM_PRIV_KEY=[$SYSTEM_PRIV_KEY]"
        echo "    IMA_PUB_CERT=[$IMA_PUB_CERT]"

        return $SWI_ERR
    fi

    mkdir -p $( dirname $IMA_PUB_CERT )
    if [ $? -ne $SWI_OK ] ; then
        echo ".ima public certificate directory could not be created."
        return $SWI_ERR
    fi

    # Check for ".ima" request for signing.
    if [ ! -f $IMA_REQSIGN_CERT ] ; then
        echo "'.ima' public key request for signing file does not exist."
        return $SWI_ERR
    fi

    # Check for ".ima" config file.
    if [ ! -f $IMA_CONF ] ; then
        echo "'.ima' config file does not exist."
        return $SWI_ERR
    fi

    # Check for ".system" public PEM cert.
    if [ ! -f $SYSTEM_PUB_CERT_PEM ] ; then
        echo "'.system' public PEM certificate file does not exist."
        return $SWI_ERR
    fi

    # Check for ".system" private key.
    if [ ! -f $SYSTEM_PRIV_KEY ] ; then
        echo "'.system' private key file does not exist."
        return $SWI_ERR
    fi

    # All is good, now we can sign request for signing.
    openssl x509 -req -in $IMA_REQSIGN_CERT -days $KEY_EXP_DAYS \
            -extfile $IMA_CONF -extensions v3_usr \
             -CA $SYSTEM_PUB_CERT_PEM -CAkey $SYSTEM_PRIV_KEY -CAcreateserial \
             -outform DER -out $IMA_PUB_CERT
    if [ $? -ne $SWI_OK ] ; then return $SWI_ERR ; fi

    return $SWI_OK
}

# Create ".system" public cert PEM file name.
# Note that we really do not care about the extension.
function get_system_cert_pem()
{
    local cert_x509=$1
    local dir=$(dirname "$cert_x509")
    local fname=$( echo `basename $cert_x509` | awk -F"." '{print $1}' )
    local ext=$( echo `basename $cert_x509` | awk -F"." '{print $2}' )
    local ret=""

    # Replace x509 filename extension with PEM extension.
    ret=$dir/$fname.pem

    echo "$ret"

    return $SWI_OK
}

# Check the environment we run this executable in.
function check_env()
{
    # We really need getopt
    if [ "x$( which getopt )" == "x" ] ; then
        echo "Please, install GNU getopt."
        return $SWI_ERR
    fi

    # And we need openssl
    if [ "x$( which openssl )" == "x" ] ; then
        echo "Please, install openssl."
        return $SWI_ERR
    fi

    return $SWI_OK
}

function main()
{
    # Check our environment
    check_env
    if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi

    # parse passed options
    parse_options "$@"
    if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi

    # generate all keys
    if [ "x$GEN_ALL_KEYS" == "xtrue" ] ; then
        # Some options do not make sense together.
        GEN_SYSTEM_KEYS=false
        GEN_IMA_KEYS=false
        create_all_keys
        if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi
    fi

    if [ "x$GEN_SYSTEM_KEYS" == "xtrue" ] ; then
        create_system_keys
        if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi
    fi

    if [ "x$GEN_IMA_KEYS" == "xtrue" ] ; then
        create_ima_keys
        if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi
    fi

    # Do we need to sign ".ima" request for signing?
    if [ "x$SIGN_IMA_REQ" == "xtrue" ] ; then
        sign_ima_req
        if [ $? != $SWI_OK ] ; then return $SWI_ERR ; fi
    fi

    return $SWI_OK
}

# This is where it all begins
main "$@"
