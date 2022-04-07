# Revert the effect of https://patchwork.openembedded.org/patch/167782/
do_cve_check[depends] += "${PN}:do_unpack"
