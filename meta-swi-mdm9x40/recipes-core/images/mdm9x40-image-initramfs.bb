require ../../../meta-swi-mdm9xxx/recipes-core/images/mdm9xxx-image-initramfs.inc

PACKAGE_INSTALL_append = " cryptsetup libgcrypt"
