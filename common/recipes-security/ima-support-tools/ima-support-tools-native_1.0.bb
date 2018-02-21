# 'require' is used instead of 'include', because 'require'
# fails if file cannot be found.
require ima-support-tools_${PV}.bb

SUMMARY = "IMA support tools"
DESCRIPTION = "Tools for IMA signage, key generation, etc."
DEPENDS = ""
PROVIDES += "ima-support-tools-native"

inherit native

do_install_append() {
    # Install IMA keys into temporary build directory. They are currently installed
    # for reference only.
    if [ "x${IMA_BUILD}" == "xtrue" ] ; then
        install -m 0644 ${IMA_LOCAL_CA_X509} -D ${D}/${sysconfdir}/ima/keys/system/$( basename ${IMA_LOCAL_CA_X509} )
        install -m 0644 ${IMA_PRIV_KEY} -D ${D}/${sysconfdir}/ima/keys/ima/$( basename ${IMA_PRIV_KEY} )
	    install -m 0644 ${IMA_PUB_CERT} -D ${D}/${sysconfdir}/ima/keys/ima/$( basename ${IMA_PUB_CERT} )
    fi
}
