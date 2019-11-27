inherit android-signing

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI = "file://init.sh \
          "

python get_verity_key_id() {
    key_id = verity_key_id(d, "testkey")
    d.setVar("VERITY_KEY_ID", key_id)
}

do_install[prefuncs] += "${@bb.utils.contains('MACHINE_FEATURES', \
                            'android-verity', 'get_verity_key_id', '', d)}"

do_install_append() {
    sed -i "s/^VERITY_KEY_ID=.*/VERITY_KEY_ID=\"${VERITY_KEY_ID}\"/g" ${D}/init
}
