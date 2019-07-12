PACKAGECONFIG_append = " ${@bb.utils.filter('DISTRO_FEATURES', 'xattr', d)}"
