
do_install() {
    install -m 0755 ${WORKDIR}/init.sh ${D}/init
}

# force do_install task to run for synchronizing roothash
do_install[nostamp] = "1"
do_install[depends] += "mdm9x28-image-minimal:do_image_complete"
