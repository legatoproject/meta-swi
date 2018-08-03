inherit autotools-brokensep module
#inherit autotools-brokensep module qperf

DESCRIPTION = "Qualcomm Atheros WLAN CLD high latency driver"
LICENSE = "ISC"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=f3b90e78ea0cffb20bf5cca7947a896d"

# Must be in sync with amss.xml.
# Tag LE.UM.1.1-47600-9x07
SRCREV = "61a7e18f7703dac9e902b31c82593502f881804b"
SRC_REPO = "git://codeaurora.org/platform/vendor/qcom-opensource/wlan/qcacld-2.0;branch=wlan-cld2.driver.lnx.1.0.c4-rel"

PR = "r0"

FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}-files:"

SRC_URI = "${SRC_REPO}"
S = "${WORKDIR}/git"

# Patches
SRC_URI += "file://bdwlan.bin \
	    file://qwlan.bin \
	    file://otp.bin \
            file://0001-compile-options.patch \
           "

# Targets - mdm9650 and sdxhedgehog: modulename = wlan_sdio.ko, chip name - qca9377
# Other targets : modulename = wlan.ko, chip name -

python __anonymous () {
     if d.getVar('BASEMACHINE', True) == 'mdm9650':
         d.setVar('WLAN_MODULE_NAME', 'wlan_sdio')
         d.setVar('CHIP_NAME', 'qca9377')
     elif d.getVar('BASEMACHINE', True) == 'sdxhedgehog':
         d.setVar('WLAN_MODULE_NAME', 'wlan_sdio')
         d.setVar('CHIP_NAME', 'qca9377')
     else:
         d.setVar('WLAN_MODULE_NAME', 'wlan')
         d.setVar('CHIP_NAME', '')
}

FILES_${PN}     += "lib/firmware/wlan/*"
FILES_${PN}     += "lib/firmware/*"
FILES_${PN}     += "${base_libdir}/modules/${KERNEL_VERSION}/extra/${WLAN_MODULE_NAME}.ko"
# The inherit of module.bbclass will automatically name module packages with
# kernel-module-" prefix as required by the oe-core build environment. Also it
# replaces '_' with '-' in the module name.
RPROVIDES_${PN} += "${@'kernel-module-${WLAN_MODULE_NAME}'.replace('_', '-')}"
PROVIDES_NAME   = "kernel-module-${WLAN_MODULE_NAME}"

do_unpack[deptask] = "do_populate_sysroot"
PR = "r0"

#This DEPENDS is to serialize kernel module builds
#DEPENDS = "rtsp-alg"

# Append the chip name to firmware installation path
CHIP_NAME_APPEND = "${@base_conditional('CHIP_NAME', '', '', '/${CHIP_NAME}', d)}"
FIRMWARE_PATH = "${D}/lib/firmware/wlan/qca_cld${CHIP_NAME_APPEND}"

# Explicitly disable LL to enable HL as current WLAN driver is not having
# simultaneous support of HL and LL.
#EXTRA_OEMAKE += "CONFIG_CLD_LL_CORE=n CONFIG_CNSS_PCI=n MODNAME=${WLAN_MODULE_NAME} CHIP_NAME=${CHIP_NAME}"

# The common header file, 'wlan_nlink_common.h' can be installed from other
# qcacld recipes too. To suppress the duplicate detection error, add it to
# SSTATE_DUPWHITELIST.
SSTATE_DUPWHITELIST += "${STAGING_DIR}/${MACHINE}${includedir}/qcacld/wlan_nlink_common.h"

do_install () {
    module_do_install

    install -d ${FIRMWARE_PATH}
    install -m 0644 ${S}/firmware_bin/WCNSS_cfg.dat ${FIRMWARE_PATH}/
    install -m 0644 ${S}/firmware_bin/WCNSS_qcom_cfg.ini ${FIRMWARE_PATH}/

    install -d ${D}${includedir}/qcacld/
    install -m 0644 ${S}/CORE/SVC/external/wlan_nlink_common.h ${D}${includedir}/qcacld/

    install -d ${D}/lib/firmware/

    install -m 0644 ${WORKDIR}/bdwlan.bin ${D}/lib/firmware/
    install -m 0644 ${WORKDIR}/otp.bin ${D}/lib/firmware/
    install -m 0644 ${WORKDIR}/qwlan.bin ${D}/lib/firmware/

    #copying wlan.ko to STAGING_DIR_TARGET
    WLAN_KO=${@base_conditional('PERF_BUILD', '1', '${STAGING_DIR_TARGET}-perf', '${STAGING_DIR_TARGET}', d)}
    install -d ${WLAN_KO}/wlan
    install -m 0644 ${S}/wlan.ko ${WLAN_KO}/wlan/
}


#addtask module_signing after do_package before do_package_write_ipk
