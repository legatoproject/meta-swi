# We don't want this package to exist on the target so we are trying to remove it.


# We have to neuter this function in update-rc.d.bbclass because this package generates "postinsts"
# scripts which we don't want.
populate_packages_updatercd() {
}

# Note that rootfs.py removes this package if it's not needed. So it's not necessary to remove files
# created in do_install.
