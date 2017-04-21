# common signing variables

ANDROID_SIGNING_DIR = "${STAGING_DIR_NATIVE}/usr/share/android-signing"

DEPENDS += "android-signing-native"

# sign image and append Android signature
android_signature_add() {
    local image_type=$1
    local unsigned_image_path=$2
    local signed_image_path=$3

    ${ANDROID_SIGNING_DIR}/verity/boot_signer $image_type \
                ${unsigned_image_path} \
                ${ANDROID_SIGNING_DIR}/security/verity.pk8 ${ANDROID_SIGNING_DIR}/security/verity.x509.pem \
                ${signed_image_path}

    # append cert chain if exists
    if [ -e ${ANDROID_SIGNING_DIR}/security/AttestationCA.der ]; then
      cat ${ANDROID_SIGNING_DIR}/security/AttestationCA.der >> ${signed_image_path}
    fi
    if [ -e ${ANDROID_SIGNING_DIR}/security/RootCA.der ]; then
      cat ${ANDROID_SIGNING_DIR}/security/RootCA.der >> ${signed_image_path}
    fi
}

