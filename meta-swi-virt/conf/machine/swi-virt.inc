# Common definitions for swi-virt images

PREFERRED_PROVIDER_virtual/kernel ?= "linux-yocto"

PREFERRED_VERSION_readline = "5.2"

LEGATO_ROOTFS_TARGETS ?= "virt"

# Remove unneeded features
MACHINE_FEATURES_remove = "screen"
DISTRO_FEATURES_remove = "x11"

# To prevent busy-box hwclock dependency creation
MACHINE_FEATURES_BACKFILL_CONSIDERED = "rtc"

IMAGE_FSTYPES += "squashfs-lzo"
