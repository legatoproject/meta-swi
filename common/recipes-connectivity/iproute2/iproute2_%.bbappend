# Add bridge
EXTRA_OEMAKE = "CC='${CC}' KERNEL_INCLUDE=${STAGING_INCDIR} DOCDIR=${docdir}/iproute2 SUBDIRS='lib tc ip bridge' SBINDIR='${base_sbindir}' LIBDIR='${libdir}'"
