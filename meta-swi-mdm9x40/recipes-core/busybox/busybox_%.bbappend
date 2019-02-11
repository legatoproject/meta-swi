do_configure_prepend(){
    sed -i 's/# CONFIG_VCONFIG is not set/CONFIG_VCONFIG=y/' ${WORKDIR}/defconfig
    sed -i 's/# CONFIG_LSPCI is not set/CONFIG_LSPCI=y/' ${WORKDIR}/defconfig
}
