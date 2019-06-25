require linux-libc-headers.inc

SRC_URI += "\
    file://${LINUXLIBCVERSION}/0001-libc-compat.h-fix-some-issues-arising-from-in6.h.patch \
    file://0002-libc-compat.h-prevent-redefinition-of-struct-ethhdr.patch \
    file://0003-remove-inclusion-of-sysinfo.h-in-kernel.h.patch \
    file://0001-if_ether-move-muslc-ethhdr-protection-to-uapi-file.patch \
    file://0004-Avoid-in6_addr-redefinition.patch \
"

SRC_URI[md5sum] = "0829b850c32c9c36721a6efc0fb2f393"
SRC_URI[sha256sum] = "18c38901c51373853435d364422c1931ed0520b16cc4ae9440d7b2095bdce2e0"
