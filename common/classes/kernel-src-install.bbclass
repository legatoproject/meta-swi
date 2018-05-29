kernel_src_install() {
    local dest=${D}${KERNEL_SRC_PATH}
    local dest_pref=$dest/usr

    # Install sanitized headers for user space use.

    mkdir -p $dest_pref
    oe_runmake headers_install INSTALL_HDR_PATH=$dest_pref

    # Install kernel tree materials needed for kernel module builds.
    # For this, we make a sparse copy of the entire kernel source tree,
    # excluding things like Documentation and .c files,
    # but keeping Makefiles and headers.

    # We get some of this material from the pristine source tree:

    echo "Installing files from sources (from ${STAGING_KERNEL_DIR}):"
    ( cd ${STAGING_KERNEL_DIR}

      ( find . \
          -type f \
          \( -name '*.h' -o \
             -name 'Makefile*' -o \
             -name 'Kconfig*' -o \
             -name 'Kbuild*' -o \
             -name '*.include' \)
        find scripts \
          -type f ) | cpio -o ) | \
     ( cd $dest
       cpio -id --no-preserve-owner )

    # We get the generated materials from the build directory:
    # This includes generated headers, config include Makefiles,
    # the .config file and System.map:

    echo "Installing generated files (from ${STAGING_KERNEL_BUILDDIR}):"
    ( cd ${STAGING_KERNEL_BUILDDIR}

      ( find . \
          -type f | grep -v '^./scripts/' ) | cpio -o ) | \
    ( cd $dest
      cpio -id --no-preserve-owner )

    # Hack for various apps_proc packages on the mdm9x15:
    # audio-alsa, audcal and others. These include the non-sanitized
    # kernel headers like <linux/compiler.h> and others which are
    # in $dest rather than $dest_pref and expect them to be in the
    # same location as sanitized headers.
    #
    # For these applications, we just merge the unsanitized headers
    # into the sanitized ones.
    #
    # We can't just copy the unsanitized headers into the sanitized
    # header tree. For each unsanitized header which has a sanitized
    # counterpart, we want the sanitized counterpart to take precedence.
    # So we combine them in a temporary directory.

    mkdir -p $dest_pref/include
    mkdir -p temp_dir

    cp -rlf $dest/include/. temp_dir/.
    cp -rlf $dest_pref/include/. temp_dir/.
    cp -rlf temp_dir/. $dest_pref/include/.

    rm -rf temp_dir

    # Finally, remove some strange /usr/src/usr cruft installed
    # by headers_install that lies outside of $dest.

    rm -rf ${D}/usr/src/usr
}

