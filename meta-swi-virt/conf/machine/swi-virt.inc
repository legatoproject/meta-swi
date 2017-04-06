# Common definitions for swi-virt images

PREFERRED_PROVIDER_virtual/kernel ?= "linux-yocto"

# Workaround for Legato not working on version 4.8 of the kernel
# TODO: Remove once LE-7010 has been fixed.
PREFERRED_VERSION_linux-yocto = "4.4%"

PREFERRED_VERSION_readline = "5.2"

LEGATO_ROOTFS_TARGETS ?= "virt"

# To prevent busy-box hwclock dependency creation
MACHINE_FEATURES_BACKFILL_CONSIDERED = "rtc"
