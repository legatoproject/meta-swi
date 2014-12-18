S = "${WORKDIR}/procps-${PV}"

FILES_${PN}-dev += "${base_libdir}/*.so"

do_install_append() {

    # Install libproc headers
    install -d ${D}${includedir}/proc
    for header in $(find ${S}/proc -name "*.h"); do
        header_name=`basename $header`
        echo "$header => $header_name"
        install -m 0644 $header ${D}${includedir}/proc/$header_name
    done

    # Generate so symlink
    cd ${D}${base_libdir} && ln -s libproc-${PV}.so libproc.so
}

