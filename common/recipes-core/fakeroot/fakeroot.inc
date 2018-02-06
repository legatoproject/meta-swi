FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# From http://ftp.debian.org/debian/pool/main/f/fakeroot/fakeroot_1.22-2.debian.tar.xz
SRC_URI += "file://eglibc-fts-without-LFS.patch \
            file://fix-shell-in-fakeroot.patch \
            file://hide-dlsym-error.patch \
            file://glibc-xattr-types.patch \
           "

# Sierra Wireless home grown ...
SRC_URI += "file://0001-cability-Fix-libfakeroot.c-related-compilation-error.patch"
