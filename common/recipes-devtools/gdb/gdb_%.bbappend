# Stage gdbserver in the sysroot as to make it available for legato-af

SYSROOT_PREPROCESS_FUNCS += "gdbserver_sysroot_preprocess"

gdbserver_sysroot_preprocess () {
    install -d ${SYSROOT_DESTDIR}${bindir}/
    install -m 755 ${D}${bindir}/gdbserver ${SYSROOT_DESTDIR}${bindir}/
}

# Default PACKAGECONFIG relies on readline while being incompatible with readline 5.2
PACKAGECONFIG=""
