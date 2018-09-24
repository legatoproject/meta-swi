#
# This class applies a solution to the standard extrausers class that
# isn't otherwise available until Poky 2.3.  The following commit is
# mimicked by using this class instead of extrausers from Poky 2.2.
# ===================================================================
# commit	280c83335a7418e280ed4b56ee4a089dba010dc3
#
# extrausers.bbclass: Use PACKAGE_INSTALL instead of IMAGE_INSTALL
# The initramfs image recipes changed to use PACKAGE_INSTALL
# so they will not be affected by IMAGE_INSTALL, and will cause
# error when inherit extrausers:
#
# | ERROR: core-image-minimal-initramfs-1.0-r0 do_rootfs:
#   core-image-minimal-initramfs: usermod command did not succeed.
#
# So use PACKAGE_INSTALL as well in extrausers.bbclass to fix it.
#
# (From OE-Core rev: fa541362e2d2cc0494a86a413b7b52dfe3eee908)
#
# Signed-off-by: Jackie Huang <jackie.huang@windriver.com>
# Signed-off-by: Ross Burton <ross.burton@intel.com>
# Signed-off-by: Richard Purdie <richard.purdie@linuxfoundation.org>
#

inherit extrausers

IMAGE_INSTALL_append = ""
PACKAGE_INSTALL_append = " ${@['', 'base-passwd shadow'][bool(d.getVar('EXTRA_USERS_PARAMS', True))]}"
