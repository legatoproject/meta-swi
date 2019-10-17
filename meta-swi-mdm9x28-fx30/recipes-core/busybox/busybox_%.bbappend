do_configure_prepend() {
    sed -i 's/# CONFIG_UDHCPD is not set/CONFIG_UDHCPD=y/' ${WORKDIR}/defconfig
}
