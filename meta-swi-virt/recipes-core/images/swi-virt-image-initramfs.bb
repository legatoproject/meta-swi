inherit swi-image-initramfs

PACKAGE_INSTALL:append = " initramfs-virtinit"

# Package IMA policy with kernel
PACKAGE_INSTALL:append = " ima-policy"
