FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += " \
           file://0001-ALPC-111-Enable-GPIO23-during-bootloader-initializat.patch \
           file://0002-ALPC-139-DV3.1-GPIO23-system-shutdown.patch \
           file://0003-ALPC-232-Provide-factory-default-recovery-mechanism.patch \
           "

S = "${WORKDIR}/git"
