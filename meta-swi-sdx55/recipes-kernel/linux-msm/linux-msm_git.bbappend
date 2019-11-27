SRC_URI += "file://smack.cfg \
            file://ubiblock.cfg \
            file://squashfs.cfg \
            "

SRC_URI += "${@bb.utils.contains('MACHINE_FEATURES', \
            'android-verity','file://android-verity.cfg','',d)}"
