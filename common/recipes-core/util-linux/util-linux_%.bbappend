# To get the following done during build time:
#   RRECOMMENDS:util-linux:remove = " util-linux-scriptlive".
# We cannot use BAD_RECOMMENDATIONS, since that variable is used only during do_install, which is
# before the PACKAGE_PREPROCESS_FUNCS where the RRECOMMENDS are being updated by util-linux
# recipe.
PACKAGE_PREPROCESS_FUNCS += "remove_util_linux_binpackages"

python remove_util_linux_binpackages() {
    pn = d.getVar('PN')
    bad_recommends = [
                      pn + '-scriptlive',
                     ]
    rrecommends = bb.utils.explode_dep_versions2(d.getVar('RRECOMMENDS:' + pn) or "")
    for pkg in bad_recommends:
        if pkg in rrecommends:
            del rrecommends[pkg]
    d.setVar('RRECOMMENDS:' + pn, bb.utils.join_deps(rrecommends, commasep=False))
}
