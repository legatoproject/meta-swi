
# Workaround to prevent dependency on bash
# Some scripts are using bash so this won't be enterily functional
RDEPENDS:${PN}-client = "rpcbind"
RDEPENDS:${PN} = "${PN}-client"

remove_bash() {
    grep -rlI "bash" ${S} | xargs sed -i 's/bash/sh/g'
}

do_patch[postfuncs] += "remove_bash"

