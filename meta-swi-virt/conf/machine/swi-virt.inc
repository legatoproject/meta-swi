# Common definitions for swi-virt images

PREFERRED_PROVIDER_virtual/kernel ?= "linux-yocto"

PREFERRED_VERSION_readline = "5.2"

LEGATO_ROOTFS_TARGETS ?= "virt"

# To prevent busy-box hwclock dependency creation
MACHINE_FEATURES_BACKFILL_CONSIDERED = "rtc"
