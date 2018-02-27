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

    ( cd ${STAGING_KERNEL_DIR}

      find . \
          -type f \
          \( -name '*.h' -o \
             -name 'Makefile' -o \
             -name 'Makefile*' -o \
             -name 'Kconfig' -o \
             -name 'Kconfig*' -o \
             -name '*.include' \) \
          -exec sh -c "mkdir -p $dest/\$(dirname {}); cp -f {} $dest/{}" \;

      cp -fr scripts $dest )

    # We get the generated materials from the build directory:
    # This includes generated headers, config include Makefiles,
    # the .config file and System.map:

    ( cd ${B}

      find . \
          -type f \
          \( -name '*.conf' -o \
             -name '*.conf.*' \) \
          -exec sh -c "mkdir -p $dest/\$(dirname {}); cp -f {} $dest/{}" \;

      find . \
          -type d -a \
          -name generated \
          -exec sh -c "mkdir -p $dest/\$(dirname {}); cp -fr {} $dest/{}" \; )

    cp -f ${B}/.config ${B}/Module.symvers $dest

    cp -f ${B}/System.map $dest/System.map-${LINUX_VERSION}

    # Finally, remove some strange /usr/src/usr cruft installed
    # by headers_install that lies outside of $dest.

    rm -rf ${D}/usr/src/usr
}
