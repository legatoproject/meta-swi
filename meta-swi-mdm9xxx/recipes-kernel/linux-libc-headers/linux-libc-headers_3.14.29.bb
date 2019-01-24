require linux-libc-headers.inc

SRC_URI += "\
    file://0001-libc-compat.h-fix-some-issues-arising-from-in6.h.patch \
    file://0002-libc-compat.h-prevent-redefinition-of-struct-ethhdr.patch \
    file://0003-remove-inclusion-of-sysinfo.h-in-kernel.h.patch \
    file://0001-if_ether-move-muslc-ethhdr-protection-to-uapi-file.patch \
"

SRC_URI[md5sum] = "a745f70181b573a34579d685ca16370e"
SRC_URI[sha256sum] = "bb38f4d3d7e6d2f873fbfdc91095128ba68da39804c5c7e1bac19dbdc0fd7442"
