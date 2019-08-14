ERROR_QA_remove = " unknown-configure-option"
WARN_QA_append = " unknown-configure-option"

EXTRA_OECONF = "--with-kernel=${STAGING_KERNEL_DIR} \
                --enable-target=${BASEMACHINE_QCOM} \
                --with-sanitized-headers=${STAGING_KERNEL_BUILDDIR}/usr/include --with-glib"
