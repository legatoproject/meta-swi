FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# Tell preprocessor that it needs to handle FX30 additions. No CONFIG_???
# is passed to the device tree compiler. So, make sure that if any #ifdef-ing
# is required in dts or dtsi files, you add it to EXTRA_DTC_CPP_FLAGS.
# Maybe CONFIG_GPIO_SWIMCU is required for mdm9x15 platforms, because it is
# defined in mdm9615_defconfig ? However, this would affect certain GPIOs.
export EXTRA_DTC_CPP_FLAGS = " -DCONFIG_SIERRA_AIRLINK_COLUMBIA -DCONFIG_GPIO_SWIMCU"

# When bitbake applies patches to the source directory index, it preserves the
# original AuthorDate of the commit, but not the CommitDate. Thus, the SHA for
# each commit differs from one build to the next. This renders the SHA that is
# presented on the device (ATI8 etc...) of no value. However, setting the value
# of GIT_COMMITTER_DATE to a fixed nominal date ensures that all patches
# applied to the build have a deterministic SHA.
do_patch_prepend() {
	export GIT_COMMITTER_DATE="1970-01-01 00:00:00"
}

do_configure_append() {

        # Take care of the FX30 kernel config.
        cat ${S}/arch/arm/configs/mdm9615-fx30_defconfig >> ${B}/.config

	cd ${S}
	kernel_ver=$(git rev-parse --short=10 HEAD)
	kernel_meta_ver=$(git rev-parse --short=10 --branches='*meta-*' HEAD | head -1)

	# Replace kernel version
	LINUX_VERSION_EXTENSION=$(echo ${PV} | sed -e "s/\([[:xdigit:]]\{10\}\)/$kernel_meta_ver/")

	# Replace kernel meta version
	LINUX_VERSION_EXTENSION=$(echo ${PV} | sed -e "s/\(_[[:xdigit:]]\{10\}\)/_$kernel_ver/")

	# Last entry will take precedence in Kconfig
	echo "CONFIG_LOCALVERSION="\"$LINUX_VERSION_EXTENSION\" >> ${B}/.config
}
