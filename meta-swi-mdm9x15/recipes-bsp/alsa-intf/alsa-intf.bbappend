FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
SRC_URI += "file://0001-SBM-16534-12181-aplay-arec-amix-consume-too-much-CPU-resource.patch"
SRC_URI += "file://0002-SBM-17175-optimize-aplay-arec.patch"
SRC_URI += "file://0003-SBM-17419-audio-not-work-with-i2s.patch"
SRC_URI += "file://0004-Fix-build-without-QC-headers.patch"
SRC_URI += "file://0005-SBM-83165-no-voice-after-stress-call-test.patch"
SRC_URI += "file://0006-ANO-91928-swiapp-is-down-after-stress-test.patch"
SRC_URI += "file://0007-ANO-92208-audio-mute-during-stress-test.patch"
