#!/bin/sh
#
# Script to build .cwe files for download via 'FDT'
#
# !!NOTE!!:  On some virtualized hosts (e.g. Virtual Box) the
#            hdrcnv utility will not run if it is on a shared
#            windows folder.  I.e. it must be on the Linux
#            drive.
#            The problem is that the dynamic linker will throw
#            an error
#
#set -x
#ln -s /bin/rm del
#PATH=.:$PATH

# Usage message
#
USAGE="`basename $0` [-o <filename>] [-z] [-fbt <Fast Boot>] [-rfs <root fs>] [-kernel <Linux Kernel>] [-ufs <GOS2 elf>] [-uapp <fs>] [-pid <package ID>]\n\n

All arguments are optional: \n
-o    <filename> output file(default output file yocto.cwe or yoctoz.cwe)\n
-z  to gernerate cwe with zip format \n
-fbt  fast boot image, default file appsboot.mbn\n
-vfbt  boot image version file, default use timestamp as version\n
-rfs  rootfs binary, default file rootfs\n
-vrfs  rootfs image version file, default use timestamp as version\n
-kernel  kernel image, default file kernel\n
-vkernel  kernel image version file, default use timestamp as version\n
-ufs  Legato file system image\n
-vufs  Legato image version file, default use timestamp as version\n
-uapp  Storage file system image\n
-vuapp  Storage image version file, default use timestamp as version\n
-pid  CWE package ID(default is 'A911' for AR755x 2G/4G memory products; use '9X15' for WP710x products) \n
at least fast boot image, root fs, kernel image are needed to generate yocto cwe file\n
-rcy create recovery kernel image cwe header"

TOOLDIR=`dirname $0`
OUTFILE=`pwd`/yocto.cwe
OUTZFILE=`pwd`/yoctoz.cwe
RFS_FILE=""
RFS_VERSION_FILE=""
UFS_FILE=""
UFS_VERSION_FILE=""
FBT_FILE=""
FBT_VERSION_FILE=""
KERNEL_FILE=""
KERNEL_VERSION_FILE=""
UAPP_FILE=""
UAPP_VERSION_FILE=""

# create a symlink hdrcnv to the real hdrcnv utility
HDRCNV=""
ARCH=$(uname -m)
HDRCNV=hdrcnv
CWEZIP=cwezip

y=${1%.*}
DATESTAMP=$(date)
COMPAT_BYTE=00000001
PLATFORM=9X15
PKID=A911

APPL_SIG=0000

ZIP_EN="no"

RFS_VERSION="${DATESTAMP}"
UFS_VERSION="${DATESTAMP}"
UAPP_VERSION="${DATESTAMP}"
FBT_VERSION="${DATESTAMP}"
KERNEL_VERSION="${DATESTAMP}"
KERNEL_RCY="no"

# Parse parameter list
#
until [ -z "$1" ]  # Until all parameters used up...
  do
  case $1 in
      "-o" | "-O")              # output file name
          shift
          OUTFILE=$1
          OUTZFILE=$1
          ;;

      "-z" | "-Z")              # enable ZIP
          ZIP_EN="yes"
          ;;

      "-rfs" | "-RFS")        # root fs file
          shift
          RFS_FILE=$1
          ;;

      "-vrfs" | "-VRFS")      # root fs version file
          shift
          RFS_VERSION_FILE=$1
          ;;

      "-ufs" | "-UFS")        # user fs file
          shift
          UFS_FILE=$1
          ;;

      "-vufs" | "-VUFS")      # user fs version file
          shift
          UFS_VERSION_FILE=$1
          ;;

      "-uapp" | "-UAPP")        # user app fs file
          shift
          UAPP_FILE=$1
          ;;

      "-vuapp" | "-VUAPP")      # user app fs version file
          shift
          UAPP_VERSION_FILE=$1
          ;;

      "-fbt" | "-FBT")        # boot image
          shift
          FBT_FILE=$1
          ;;

      "-vfbt" | "-VFBT")      # boot image version file
          shift
          FBT_VERSION_FILE=$1
          ;;

      "-kernel" | "-KERNEL")        # kernel image
          shift
          KERNEL_FILE=$1
          ;;

      "-vkernel" | "-VKERNEL")      # kernel image version file
          shift
          KERNEL_VERSION_FILE=$1
          ;;

      "-pid" | "-PID")        # product ID
          shift
          PKID=$1
          ;;

      "-platform" | "-PLATFORM")    # platform
          shift
          PLATFORM=$1
          ;;

      "-prod" | "-PROD")
          shift
          PROD=$1
          ;;

      "-rcy" | "-RCY")
          KERNEL_RCY="yes"
          ;;

      "-h" | "--help")
          echo -e $USAGE
          exit 1
          ;;

      *)
          echo -e "unrecognized argument: $1\n"
          echo -e $USAGE
          exit 1
  esac
  shift
done

TMPMBN=`dirname ${OUTFILE}`/temp.mbn

if [ "${ZIP_EN}" = "yes" ] ; then
      OUTFILE=$OUTZFILE
fi

if [ -f ${TMPMBN} ] ; then
    rm -f ${TMPMBN}.data
fi

if [ -f ${OUTFILE} ] ; then
    rm -f ${OUTFILE}
fi

function check_exist() {
  IMG_FILE=$1

  if ! [ -e "$IMG_FILE" ] ; then
    echo "ERROR: $IMG_FILE doesn't exist"
    exit 1
  fi
}

if [ -n "${RFS_FILE}" ] ; then
    echo -e "\nGenerating CWE for rootfs ${RFS_FILE}"
    check_exist ${RFS_FILE}
    if [ -n "${RFS_VERSION_FILE}" ] ; then RFS_VERSION=$(cat ${RFS_VERSION_FILE}); fi
    if [ -f ${TMPMBN} ] ; then rm -f ${TMPMBN}; fi
    if [ -f ${TMPMBN}.hdr ] ; then rm -f ${TMPMBN}.hdr; fi
    if [ -f ${TMPMBN}.cwe ] ; then rm -f ${TMPMBN}.cwe; fi
    cp ${RFS_FILE} ${TMPMBN}
    $HDRCNV ${TMPMBN} -OH ${TMPMBN}.hdr -IT SYST -PT $PLATFORM -V "${RFS_VERSION}" -B $COMPAT_BYTE
    cat ${TMPMBN}.hdr ${TMPMBN} > ${TMPMBN}.cwe
    if [ "${ZIP_EN}" = "yes" ] ; then
        if [ -f ${TMPMBN}.cwe.z ] ; then rm -f ${TMPMBN}.cwe.z; fi
        $CWEZIP  ${TMPMBN}.cwe -c -o  ${TMPMBN}.cwe.z
        dd if=${TMPMBN}.cwe.z >> ${TMPMBN}.data
    else
        dd if=${TMPMBN}.cwe >> ${TMPMBN}.data
    fi
fi

if [ -n "${UFS_FILE}" ] ; then
    echo -e "\nGenerating CWE for userfs ${UFS_FILE}"
    check_exist ${UFS_FILE}
    if [ -n "${UFS_VERSION_FILE}" ] ; then
        TMP_VERSION=$(cat ${UFS_VERSION_FILE} | cut -d' ' -f1)
        TMP_TIME=$(cat ${UFS_VERSION_FILE} | cut -d' ' -f3-)
        UFS_VERSION="$TMP_VERSION $TMP_TIME"
    fi
    if [ -f ${TMPMBN} ] ; then rm -f ${TMPMBN}; fi
    if [ -f ${TMPMBN}.hdr ] ; then rm -f ${TMPMBN}.hdr; fi
    if [ -f ${TMPMBN}.cwe ] ; then rm -f ${TMPMBN}.cwe; fi
    cp ${UFS_FILE} ${TMPMBN}
    $HDRCNV ${TMPMBN} -OH ${TMPMBN}.hdr -IT USER -PT $PLATFORM -V "${UFS_VERSION}" -B $COMPAT_BYTE
    cat ${TMPMBN}.hdr ${TMPMBN} > ${TMPMBN}.cwe
    if [ "${ZIP_EN}" = "yes" ] ; then
        if [ -f ${TMPMBN}.cwe.z ] ; then rm -f ${TMPMBN}.cwe.z; fi
        $CWEZIP  ${TMPMBN}.cwe -c -o  ${TMPMBN}.cwe.z
        dd if=${TMPMBN}.cwe.z >> ${TMPMBN}.data
    else
        dd if=${TMPMBN}.cwe >> ${TMPMBN}.data
    fi
fi

if [ -n "${FBT_FILE}" ] ; then
    echo -e "\nGenerating CWE for bootloader ${FBT_FILE}"
    check_exist ${FBT_FILE}
    if [ -n "${FBT_VERSION_FILE}" ] ; then FBT_VERSION=$(cat ${FBT_VERSION_FILE}); fi
    if [ -f ${TMPMBN} ] ; then rm -f ${TMPMBN}; fi
    if [ -f ${TMPMBN}.hdr ] ; then rm -f ${TMPMBN}.hdr; fi
    if [ -f ${TMPMBN}.cwe ] ; then rm -f ${TMPMBN}.cwe; fi
    cp ${FBT_FILE} ${TMPMBN}
    $HDRCNV ${TMPMBN} -OH ${TMPMBN}.hdr -IT APBL -PT $PLATFORM -V "${FBT_VERSION}" -B $COMPAT_BYTE
    cat ${TMPMBN}.hdr ${TMPMBN} > ${TMPMBN}.cwe
    # For AR products, LK uses "BOOT" TOP-level cwe header, but not "APPL".
    if [ "${PKID}" = "9X40" -o "${PROD}" = "ar758x" ] ; then
        dd if=${TMPMBN}.cwe >> ${TMPMBN}.boot.data
    else
        dd if=${TMPMBN}.cwe >> ${TMPMBN}.data
    fi
fi

if [ -n "${KERNEL_FILE}" ] ; then
    echo -e "\nGenerating CWE for kernel ${KERNEL_FILE}"
    check_exist ${KERNEL_FILE}
    if [ -n "${KERNEL_VERSION_FILE}" ] ; then KERNEL_VERSION=$(cat ${KERNEL_VERSION_FILE}); fi
    if [ -f ${TMPMBN} ] ; then rm -f ${TMPMBN}; fi
    if [ -f ${TMPMBN}.hdr ] ; then rm -f ${TMPMBN}.hdr; fi
    if [ -f ${TMPMBN}.cwe ] ; then rm -f ${TMPMBN}.cwe; fi
    cp ${KERNEL_FILE} ${TMPMBN}
    if [ "${KERNEL_RCY}" = "yes" ] ; then
        $HDRCNV ${TMPMBN} -OH ${TMPMBN}.hdr -IT LRAM -PT $PLATFORM -V "${KERNEL_VERSION}" -B $COMPAT_BYTE
    else
        $HDRCNV ${TMPMBN} -OH ${TMPMBN}.hdr -IT APPS -PT $PLATFORM -V "${KERNEL_VERSION}" -B $COMPAT_BYTE
    fi
    cat ${TMPMBN}.hdr ${TMPMBN} > ${TMPMBN}.cwe
    if [ "${ZIP_EN}" = "yes" ] ; then
        if [ -f ${TMPMBN}.cwe.z ] ; then rm -f ${TMPMBN}.cwe.z; fi
        $CWEZIP  ${TMPMBN}.cwe -c -o  ${TMPMBN}.cwe.z
        dd if=${TMPMBN}.cwe.z >> ${TMPMBN}.data
    else
        dd if=${TMPMBN}.cwe >> ${TMPMBN}.data
    fi
fi

if [ -n "${UAPP_FILE}" ] ; then
    echo -e "\nGenerating CWE for userapp fs ${UAPP_FILE}"
    check_exist ${UAPP_FILE}
    if [ -n "${UAPP_VERSION_FILE}" ] ; then
        TMP_VERSION=$(cat ${UAPP_VERSION_FILE} | cut -d' ' -f1)
        TMP_TIME=$(cat ${UAPP_VERSION_FILE} | cut -d' ' -f3-)
        UAPP_VERSION="$TMP_VERSION $TMP_TIME"
    fi
    if [ -f ${TMPMBN} ] ; then rm -f ${TMPMBN}; fi
    if [ -f ${TMPMBN}.hdr ] ; then rm -f ${TMPMBN}.hdr; fi
    if [ -f ${TMPMBN}.cwe ] ; then rm -f ${TMPMBN}.cwe; fi
    cp ${UAPP_FILE} ${TMPMBN}
    $HDRCNV ${TMPMBN} -OH ${TMPMBN}.hdr -IT UAPP -PT $PLATFORM -V "${UAPP_VERSION}" -B $COMPAT_BYTE
    cat ${TMPMBN}.hdr ${TMPMBN} > ${TMPMBN}.cwe
    dd if=${TMPMBN}.cwe >> ${TMPMBN}.data
fi

if [ -f "${TMPMBN}.data" ] ; then
    echo "Creating Top-level CWE header.  Type = APPL"
    $HDRCNV ${TMPMBN}.data -OH $TMPMBN.hdr -IT APPL -PT $PKID -V "${RFS_VERSION}" -B $COMPAT_BYTE

    echo "Concatenating files to create: ${OUTFILE}"
    dd if=${TMPMBN}.hdr > ${OUTFILE}
    dd if=${TMPMBN}.data >> ${OUTFILE}
fi

if [ -f "${TMPMBN}.boot.data"  ] ; then
    if [ "${PKID}" = "9X40" -o "${PROD}" = "ar758x" ] ; then
        $HDRCNV ${TMPMBN}.boot.data -OH $TMPMBN.hdr -IT BOOT -PT $PKID -V "${DATESTAMP}" -B $COMPAT_BYTE
        dd if=${TMPMBN}.hdr >> ${OUTFILE}
        dd if=${TMPMBN}.boot.data >> ${OUTFILE}
    fi
fi

rm -f ${TMPMBN}.hdr ${TMPMBN}.data ${TMPMBN} ${TMPMBN}.hdr ${TMPMBN}.cwe ${TMPMBN}.cwe.z ${TMPMBN}.boot.data

exit

