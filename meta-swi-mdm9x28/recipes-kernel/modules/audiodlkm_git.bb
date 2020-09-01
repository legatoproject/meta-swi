inherit module qperf

DESCRIPTION = "QTI Audio drivers"
LICENSE = "GPL-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/${LICENSE};md5=801f80980d171dd6425610833a22dbe6"

PR = "r0"

DEPENDS = "virtual/kernel"

FILESPATH =+ "${WORKSPACE}:"
SRC_URI = "file://vendor/qcom/opensource/audio-kernel/"
SRC_URI += "file://${BASEMACHINE}/"

S = "${WORKDIR}/vendor/qcom/opensource/audio-kernel"

FILES_${PN} += "${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/*"
FILES_${PN} += "${sysconfdir}/*"
FILES_${PN}+="/etc/initscripts/start_audio_le"

EXTRA_OEMAKE += "TARGET_SUPPORT=${BASEMACHINE}"

# Disable parallel make
PARALLEL_MAKE = ""

# Disable parallel make
PARALLEL_MAKE = "-j1"

do_configure() {
  cp -f ${WORKDIR}/vendor/qcom/opensource/audio-kernel/Makefile.am ${WORKDIR}/vendor/qcom/opensource/audio-kernel/Makefile
}

INITSCRIPT_NAME = "start_audio_le"
INITSCRIPT_PARAMS = "start 97 5 . stop 15 0 1 6 ."

do_install_append() {
  install -d ${STAGING_KERNEL_BUILDDIR}/audio-kernel/
  install -d ${STAGING_KERNEL_BUILDDIR}/audio-kernel/linux
  install -d ${STAGING_KERNEL_BUILDDIR}/audio-kernel/linux/mfd
  install -d ${STAGING_KERNEL_BUILDDIR}/audio-kernel/linux/mfd/wcd9xxx
  install -d ${STAGING_KERNEL_BUILDDIR}/audio-kernel/sound
  install -d ${D}${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra

  cp -fr ${S}/linux/* ${STAGING_KERNEL_BUILDDIR}/audio-kernel/linux
  install -m 0644 ${S}/sound/* ${STAGING_KERNEL_BUILDDIR}/audio-kernel/sound

if [ ${BASEMACHINE} != "mdm9607" ];then
  if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
  install -m 0755 ${WORKDIR}/${BASEMACHINE}/audio_load.conf -D ${D}${sysconfdir}/modules-load.d/audio_load.conf
  else
    install -m 0755 ${WORKDIR}/${BASEMACHINE}/audio_load.conf -D ${D}${sysconfdir}/modules/audio_load.conf
  fi
fi

   for i in $(find ${D}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/. -name "*.ko"); do
   mv ${i} ${D}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/
   done

   rm -fr ${D}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/asoc
   rm -fr ${D}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/dsp
   rm -fr ${D}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/ipc
   rm -fr ${D}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/soc
}

do_install_append_mdm() {
  install -m 0755 ${WORKDIR}/${BASEMACHINE}/audio_load.conf -D ${D}${sysconfdir}/modprobe.d/audio_load.conf
  install -d ${D}${sysconfdir}/init.d
  install -m 0755 ${WORKDIR}/${BASEMACHINE}/start_audio_le ${D}${sysconfdir}/init.d/start_audio_le
  install -d ${D}${systemd_unitdir}/system/multi-user.target.wants/
}

pkg_postinst_${PN} () {
    [ -n "$D" ] && OPT="-r $D" || OPT="-s"
    # remove all rc.d-links potentially created from alternatives
    update-rc.d $OPT -f ${INITSCRIPT_NAME} remove
    update-rc.d $OPT ${INITSCRIPT_NAME} start 97 5 . stop 15 0 1 6 .
}

do_module_signing() {
  if [ -f ${STAGING_KERNEL_BUILDDIR}/signing_key.priv ]; then
    for i in ${PKGDEST}/${PN}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/*
      do
        ${STAGING_KERNEL_DIR}/scripts/sign-file sha512 ${STAGING_KERNEL_BUILDDIR}/signing_key.priv ${STAGING_KERNEL_BUILDDIR}/signing_key.x509 ${i}
      done
  elif [ -f ${STAGING_KERNEL_BUILDDIR}/certs/signing_key.pem ]; then
    for i in $(find ${PKGDEST}/${PN}/${nonarch_base_libdir}/modules/${KERNEL_VERSION}/extra/* -name "*.ko");
      do
   ${STAGING_KERNEL_BUILDDIR}/scripts/sign-file sha512 ${STAGING_KERNEL_BUILDDIR}/certs/signing_key.pem ${STAGING_KERNEL_BUILDDIR}/certs/signing_key.x509 ${i}
   done
  fi
}

addtask do_module_signing after do_package before do_package_write_ipk

# The inherit of module.bbclass will automatically name module packages with
# kernel-module-" prefix as required by the oe-core build environment. Also it
# replaces '_' with '-' in the module name.
RPROVIDES_${PN} += "\
	kernel-module-apr-dlkm \
	kernel-module-adsp-loader-dlkm \
	kernel-module-q6-dlkm \
	kernel-module-platform-dlkm \
	kernel-module-stub-dlkm \
	kernel-module-wcd-core-dlkm \
	kernel-module-wcd-cpe-dlkm \
	kernel-module-wcd9330-dlkm \
	kernel-module-machine-dlkm \
	"
