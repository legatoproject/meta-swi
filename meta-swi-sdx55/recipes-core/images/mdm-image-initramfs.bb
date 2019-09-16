require ../../../meta-swi-mdm9xxx/recipes-core/images/mdm9xxx-image-initramfs.inc

# We are not adding ima-policy globally, because some of the
# kernels may not fully support ima feature set (e.g. 9x15 kernel is 3.14).
PACKAGE_INSTALL_append = " ima-policy"
