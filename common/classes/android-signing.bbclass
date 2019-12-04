# common signing variables

ANDROID_SIGNING_DIR = "${STAGING_DIR_NATIVE}/usr/share/android-signing"

DEPENDS += "android-signing-native python3 openssl-native"

# sign image and append Android signature
android_signature_add() {
    local image_type=$1
    local unsigned_image_path=$2
    local signed_image_path=$3
    local key=$4
    local attestation_ca=$5
    local root_ca=$6

    python3 ${ANDROID_SIGNING_DIR}/package_signing.py \
	-t ${image_type} \
	-f ${ANDROID_SIGNING_DIR}/py_signing.json \
	-k ${ANDROID_SIGNING_DIR}/security/${key} \
	-u ${unsigned_image_path} \
	-s ${signed_image_path}

    # append cert chain if specified
    if [ -f ${ANDROID_SIGNING_DIR}/security/${attestation_ca} ]; then
      cat ${ANDROID_SIGNING_DIR}/security/${attestation_ca} >> ${signed_image_path}
    fi
    if [ -f ${ANDROID_SIGNING_DIR}/security/${root_ca} ]; then
      cat ${ANDROID_SIGNING_DIR}/security/${root_ca} >> ${signed_image_path}
    fi
}

