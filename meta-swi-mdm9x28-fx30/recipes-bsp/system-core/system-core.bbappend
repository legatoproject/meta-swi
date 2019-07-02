# This file piggybacks on top of base meta-swi-mdm9x28 and
# FILESEXTRAPATHS_prepend set there, is valid here as well.
# That is why pathes located in its 'files' directory could
# be found here.
#
# This patch is only added for mdm9x28 (e.g. wp76), but is needed
# for fx30 product as well.
# DM, FIXME: It would be better to add this patch as
# SRC_URI only in base mdm9x28, and exclude it from products
# which are piggybacking on it. However, I have to time to
# test other platforms now.
SRC_URI_append_swi-mdm9x28-fx30 += "file://0001-Fix-build-without-liblog.patch"
