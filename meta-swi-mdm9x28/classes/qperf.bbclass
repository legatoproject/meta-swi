#
# This class helps to rebuild recipes for production images
#

# Fetch PR value and append _perf to ensure recipe rebuilds.
python __anonymous() {
    if (d.getVar('PERF_BUILD', True) == '1'):
        revision = d.getVar('PR', True)
        if (d.getVar('USER_BUILD', True) == '1'):
            revision += "_user"
        else:
            revision += "_perf"
        d.setVar('PR', revision)
}
