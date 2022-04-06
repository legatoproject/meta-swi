SUMMARY = "ima-policy"
DESCRIPTION = "IMA policy file."

# Location of non-default policy file (if any). In order for this to work,
# add IMA_POLICY_DIR variable to BB_ENV_EXTRAWHITE list. For example:
#    export BB_ENV_EXTRAWHITE="IMA_POLICY_DIR"
# COPYING file must be located in the same directory. Do not forget to
# change its md5sum below.
IMA_POLICY_DIR ?= "."

# Name of the default, base policy file.
IMA_POLICY_FILE ?= "ima.policy"

# Additional add-on policy files.
IMA_POLICY_IMMUTABLE_FILES ?= "ima-immutable-files.policy"

# Smack label which must be applied to immutable files at build time
# to protect them using IMA at run-time.
IMA_SMACK_IMMUTABLE_FILES_LABEL ?= "${IMA_SMACK}"

# Where to find additional files (patches, etc.).
FILESEXTRAPATHS:prepend := "${IMA_POLICY_DIR}:${THISDIR}/files:"

# Package revision number. Change "r" number if you change
# anything in this package (e.g. add patch, remove patch,
# change dependencies, etc.).
PR = "r1"

HOMEPAGE = "https://sourceforge.net/p/linux-ima/wiki/Home/"
LICENSE = "GPLv2"
# Make sure that there is 'file://../COPYING...' in order to avoid
# "LIC_FILES_CHKSUM points to an invalid file" error. This is because
# there is no ima-policy-1.0.tar.gz source bundle (which we do not really
# need), COPYING file is stored in files directory, and as any other patches
# and additional files in build directory, is stored one dir above
# ima-policy-1.0 directory (which in this case is empty).
LIC_FILES_CHKSUM = "file://../COPYING;md5=b234ee4d69f5fce4486a80fdaf4a4263"

# Where to find source code for this package.
SRC_URI = "file://COPYING"
SRC_URI += "file://${IMA_POLICY_FILE}"
SRC_URI += "file://${IMA_POLICY_IMMUTABLE_FILES}"

do_install() {

    if [ ! -z "${IMA_SMACK_IMMUTABLE_FILES_LABEL}" ] ; then
        # Add smack rule to protect immutable files.
        bbnote "Immutable files will be protected using ${IMA_SMACK_IMMUTABLE_FILES_LABEL} smack label."
        cat ${WORKDIR}/${IMA_POLICY_IMMUTABLE_FILES} >> ${WORKDIR}/${IMA_POLICY_FILE}
        sed -i -- 's/@@IMA_SMACK_IMMUTABLE_FILES_LABEL@@/'"${IMA_SMACK_IMMUTABLE_FILES_LABEL}"'/g' \
            ${WORKDIR}/${IMA_POLICY_FILE}
    else
        bbwarn "IMA: Immutable files will not be protected."
    fi

    # Install policy file.
    install -m 0444 ${WORKDIR}/${IMA_POLICY_FILE} -D ${D}${sysconfdir}/ima/ima.policy
}
