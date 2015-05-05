
# Workaround to prevent dependency on bash
# Some scripts are using bash so this won't be enterily functional
RDEPENDS_${PN}-client = "rpcbind"
RDEPENDS_${PN} = "${PN}-client"