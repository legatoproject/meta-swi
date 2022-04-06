do_install:append() {
    # We really do not need these, they are just taking space.
    rm -rf ${D}/etc
    rm -rf ${D}/usr/bin
}
