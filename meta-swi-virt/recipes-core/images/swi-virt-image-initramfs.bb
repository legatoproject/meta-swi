inherit swi-image-initramfs

PACKAGE_INSTALL_append = " initramfs-virtinit"

# Package IMA policy with kernel
PACKAGE_INSTALL_append = " ima-policy"
