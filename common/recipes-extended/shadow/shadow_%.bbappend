FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += " \
            file://0001-Simplify-getulong.patch \
            file://0001-Fix-a-resource-leak-in-libmis-idmapping.c.patch \
            file://0002-get_map_ranges-initialize-argidx-to-0-at-top-of-loop.patch \
            file://0003-get_map_ranges-check-for-overflow.patch \
         "
