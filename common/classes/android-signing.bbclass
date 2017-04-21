# common signing variables

ANDROID_SIGNING_DIR = "${STAGING_DIR_NATIVE}/usr/share/android-signing"

DEPENDS += "android-signing-native"

# sign image and append Android signature
android_signature_add() {
    local image_type=$1
    local unsigned_image_path=$2
    local signed_image_path=$3
    local key=$4
    local attestation_ca=$5
    local root_ca=$6

    # android-signing's boot_signer requires java from host machine
    export PATH=$PATH:/usr/bin

    ${ANDROID_SIGNING_DIR}/verity/boot_signer $image_type \
                ${unsigned_image_path} \
                ${ANDROID_SIGNING_DIR}/security/${key}.pk8 ${ANDROID_SIGNING_DIR}/security/${key}.x509.pem \
                ${signed_image_path}

    # append cert chain if specified
    if [ -f ${ANDROID_SIGNING_DIR}/security/${attestation_ca} ]; then
      cat ${ANDROID_SIGNING_DIR}/security/${attestation_ca} >> ${signed_image_path}
    fi
    if [ -f ${ANDROID_SIGNING_DIR}/security/${root_ca} ]; then
      cat ${ANDROID_SIGNING_DIR}/security/${root_ca} >> ${signed_image_path}
    fi
}

