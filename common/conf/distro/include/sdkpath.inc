
def get_default_sdkpath_prefix(d, suffix=""):
    distro_version = d.getVar('DISTRO_VERSION', True) # Format 2.5.2
    if not distro_version:
        return "yXX%s" % suffix

    import re
    m = re.match("(\d*)\.(\d*)\.", distro_version)
    if not m:
        return "%s%s" % (distro_version, suffix)

    return "y%s%s%s" % (m.group(1), m.group(2), suffix)

