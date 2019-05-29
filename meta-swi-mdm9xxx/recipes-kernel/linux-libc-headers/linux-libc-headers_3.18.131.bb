require linux-libc-headers.inc

SRC_URI += "\
    file://3.18/0001-libc-compat.h-fix-some-issues-arising-from-in6.h.patch \
    file://0002-libc-compat.h-prevent-redefinition-of-struct-ethhdr.patch \
    file://0003-remove-inclusion-of-sysinfo.h-in-kernel.h.patch \
    file://0001-if_ether-move-muslc-ethhdr-protection-to-uapi-file.patch \
    file://0004-Avoid-in6_addr-redefinition.patch \
"

SRC_URI[md5sum] = "40b69a0fcc3cb0829181d0aa0e3f4335"
SRC_URI[sha256sum] = "04600ce96e4c7642b9eaa4814f4930c79b53010b1c155d23e5ac0aeba6f455e2"
