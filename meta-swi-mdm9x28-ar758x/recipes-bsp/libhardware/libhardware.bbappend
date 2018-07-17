
# Tag LE.UM.1.2-15100-9x07
SRCREV = "2964e92c59460d4d5b5a4c28f5a0d28b1ecb8a64"
LIBHARDWARE_REPO = "git://codeaurora.org/platform/hardware/libhardware;branch=le-blast.lnx.1.1.c2-rel"
SRC_URI  = "${LIBHARDWARE_REPO}"

EXTRA_OEMAKE = "INCLUDES='-I${S}/include'"
EXTRA_OECONF = "--with-sanitized-headers=${STAGING_DIR_TARGET}${KERNEL_SRC_PATH}/usr/include"

do_install_append () {
        install -d ${D}${includedir}
        install -m 0644 ${S}/include/hardware/gps.h -D ${D}${includedir}/hardware/gps.h
        install -m 0644 ${S}/include/hardware/hardware.h -D ${D}${includedir}/hardware/hardware.h
        install -m 0644 ${S}/include/hardware/hwcomposer.h -D ${D}${includedir}/hardware/hwcomposer.h
        install -m 0644 ${S}/include/hardware/hwcomposer_defs.h -D ${D}${includedir}/hardware/hwcomposer_defs.h
        install -m 0644 ${S}/include/hardware/gralloc.h -D ${D}${includedir}/hardware/gralloc.h
        install -m 0644 ${S}/include/hardware/fused_location.h -D ${D}${includedir}/hardware/fused_location.h
        install -m 0644 ${S}/include/hardware/camera.h -D ${D}${includedir}/hardware/camera.h
        install -m 0644 ${S}/include/hardware/camera3.h -D ${D}${includedir}/hardware/camera3.h
        install -m 0644 ${S}/include/hardware/camera_common.h -D ${D}${includedir}/hardware/camera_common.h
        install -m 0644 ${S}/include/hardware/fb.h -D ${D}${includedir}/hardware/fb.h
        install -m 0644 ${S}/include/hardware/power.h -D ${D}${includedir}/hardware/power.h
        install -m 0644 ${S}/include/hardware/audio.h -D ${D}${includedir}/hardware/audio.h
        install -m 0644 ${S}/include/hardware/sound_trigger.h -D ${D}${includedir}/hardware/sound_trigger.h
        install -m 0644 ${S}/include/hardware/audio_alsaops.h -D ${D}${includedir}/hardware/audio_alsaops.h
        install -m 0644 ${S}/include/hardware/audio_effect.h -D ${D}${includedir}/hardware/audio_effect.h
        install -m 0644 ${S}/include/hardware/audio_policy.h -D ${D}${includedir}/hardware/audio_policy.h
        install -m 0644 ${S}/modules/gralloc/gralloc_priv.h -D ${D}${includedir}/
        install -m 0644 ${S}/include/hardware/sensors.h -D ${D}${includedir}/hardware/sensors.h
}

