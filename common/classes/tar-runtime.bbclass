# Generate a tarball with the runtime content
# so that it can be easily transferred and executed on
# the target.
# Dependencies are however not managed.

do_deploy_tar_runtime() {
    mkdir -p ${DEPLOY_DIR}/tar
    cd ${PKGDEST}/${PN}
    tar jcvf ${DEPLOY_DIR}/tar/${PN}-${PKGV}-${PKGR}.tar.bz2 *
    ln -sf ${PN}-${PKGV}-${PKGR}.tar.bz2 ${DEPLOY_DIR}/tar/${PN}.tar.bz2
}

addtask deploy_tar_runtime after do_package before do_build

