DESCRIPTION = "Sierra Wireless Library"
HOMEPAGE = "http://www.sierrawireless.com"
LICENSE = "SierraWireless-Proprietary"
LIC_FILES_CHKSUM = "file://LICENSE;md5=dbdf22205bb8b7f613788e897d3e869e"

DEPENDS = "cwetool"
DEPENDS += "yaffs2-utils"
DEPENDS += "legato-af"

SRC_URI += "file://LICENSE"

INC_PR = "r0"

# Target IP address (ie X.Y.Z.T) where the "golden" legato-af is installed.
# If empty, the board is skipped.
TARGET_ar86 ?= ""
TARGET_ar7 ?= ""
TARGET_wp7 ?= ""
TARGET_wp85 ?= ""

S = "${WORKDIR}"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

fakeroot do_generate_custom_cwe() {
    PAGE_SIZE=4096
    OOB_SIZE=160
    COMPAT_BYTE=00000001
    IMG_TYPE=yaffs2

    MKYAFFS2IMAGE=`which mkyaffs2image`
    HDRCNV=`which hdrcnv`
    CWEZIP=`which cwezip`

    cd ${DEPLOY_DIR_IMAGE}/

    for target in ${LEGATO_ROOTFS_TARGETS}
    do
        TARGET_IP=""
        case $target in
            ar7)
                TARGET_IP=${TARGET_ar7}
                PID='A911'
                ;;
            ar86)
                TARGET_IP=${TARGET_ar86}
                PID='A911'
                ;;
            wp7)
                TARGET_IP=${TARGET_wp7}
                PID='9X15'
                ;;
            wp85)
                TARGET_IP=${TARGET_wp85}
                PID='Y912'
                PAGE_SIZE=2048
                OOB_SIZE=64
                ;;
            *)
                echo "Target $target is currently not supported"
                ;;
        esac
        if [ -z "$TARGET_IP" ]; then
            continue
        fi 

        LEGATO_DIR=tmp_${target}
        LEGATO_IMG="legato-custom-${target}.${IMG_TYPE}"

        # Need "root" access to remove the "previous" ${LEGATO_DIR}
        test -d "${LEGATO_DIR}" && rm -rf "${LEGATO_DIR}"
        mkdir -p "${LEGATO_DIR}"

        # Need "root" access to extract the tarball
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n \
            root@${TARGET_IP} "bsdtar -C /mnt/flash -cf - opt startup startupDefaults ufs/etc/passwd ufs/etc/group" | \
            tar -C tmp_${target} -xp
        ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -n \
            root@${TARGET_IP} "bsdtar -C / -cf - usr/local" | \
            tar -C tmp_${target} -xp
        # Need "root" access to remove the builtInVersion
        rm -f tmp_${target}/opt/legato/builtInVersion

        case $IMG_TYPE in
            yaffs2)
                # Need "root" access to make the yaffs2 image
                ${MKYAFFS2IMAGE} -c $PAGE_SIZE -s $OOB_SIZE "${LEGATO_DIR}" "$LEGATO_IMG"
                chmod 644 "$LEGATO_IMG"
                VERSION=$(cat ${LEGATO_DIR}/opt/legato/version)
                ;;
            *)
                echo "Unknown image type '$IMG_TYPE'"
                exit 1
                ;;
        esac

        TMPMBN=temp.mbn
        LEGATO=legato-custom-${target}
        LEGATOZ=legatoz-custom-${target}
        if [ -f ${TMPMBN}.hdr ] ; then rm -f ${TMPMBN}.hdr; fi
        if [ -f ${TMPMBN}.cwe ] ; then rm -f ${TMPMBN}.cwe; fi
        if [ -f ${TMPMBN}.cwe.z ] ; then rm -f ${TMPMBN}.cwe.z; fi
        if [ -f ${LEGATO}.cwe ] ; then rm -f ${LEGATO}.cwe; fi
        if [ -f ${LEGATO}.hdr ] ; then rm -f ${LEGATO}.hdr; fi
        if [ -f ${LEGATOZ}.cwe ] ; then rm -f ${LEGATOZ}.cwe; fi
        if [ -f ${LEGATOZ}.hdr ] ; then rm -f ${LEGATOZ}.hdr; fi

        ${HDRCNV} ${LEGATO_IMG} -OH ${TMPMBN}.hdr -IT UAPP -PT 9X15 -V $VERSION -B $COMPAT_BYTE
        cat ${TMPMBN}.hdr ${LEGATO_IMG} > ${TMPMBN}.cwe

        # legato.cwe
        ${HDRCNV} ${TMPMBN}.cwe -OH ${LEGATO}.hdr -IT APPL -PT $PID -V $VERSION -B $COMPAT_BYTE
        cat ${LEGATO}.hdr ${TMPMBN}.cwe > ${LEGATO}.cwe

        # legatoz.cwe
        ${CWEZIP} ${TMPMBN}.cwe -c -o ${TMPMBN}.cwe.z
        ${HDRCNV} ${TMPMBN}.cwe.z -OH ${LEGATOZ}.hdr -IT APPL -PT $PID -V $VERSION -B $COMPAT_BYTE
        cat ${LEGATOZ}.hdr ${TMPMBN}.cwe.z > ${LEGATOZ}.cwe

        # Remove "temporary" files...
        rm -rf ${TMPMBN}.hdr ${TMPMBN}.cwe ${TMPMBN}.cwe.z ${LEGATO}.hdr ${LEGATOZ}.hdr

    done
}

addtask generate_custom_cwe after do_install before do_build

