# 'require' is used instead of 'include', because 'require'
# fails if file cannot be found.
require ima-support-tools_${PV}.bb

PROVIDES += "ima-support-tools-native"

inherit native

do_install:append() {
    # Install IMA certificates into temporary build directory. They are currently installed
    # for reference only.
    if [ "x${IMA_BUILD}" == "xtrue" ] ; then
        install -m 0644 ${IMA_LOCAL_CA_X509} -D ${D}/${sysconfdir}/ima/keys/system/$( basename ${IMA_LOCAL_CA_X509} )
        install -m 0644 ${IMA_PUB_CERT} -D ${D}/${sysconfdir}/ima/keys/ima/$( basename ${IMA_PUB_CERT} )
    fi
}
