FILESEXTRAPATHS_prepend := "${LINUX_REPO_DIR}/net:"

SRC_URI = "file://embms_kernel \
           file://start_embms_le \
           file://embmsd.service"

S = "${WORKDIR}/embms_kernel"
do_install_append_mdm() {
        if ${@bb.utils.contains('DISTRO_FEATURES', 'systemd', 'true', 'false', d)}; then
              rm -rf ${D}${sysconfdir}/init.d/
        fi
}
