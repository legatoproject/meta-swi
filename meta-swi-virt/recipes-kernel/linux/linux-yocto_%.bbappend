inherit kernel-src-install

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += "file://squashfs.cfg"
SRC_URI += "file://smack.cfg"
SRC_URI += "file://pm.cfg"
SRC_URI += "file://overlayfs.cfg"
SRC_URI += "file://ima.cfg"
SRC_URI += "file://audit.cfg"

RDEPENDS:${PN} += "kern-tools-native"

PACKAGES:prepend = "kernel-tools "
FILES:kernel-tools = "${KERNEL_SRC_PATH}/arch/*/tools/* \
                      ${KERNEL_SRC_PATH}/arch/*/tools/.debug/*"
INSANE_SKIP:kernel-tools = "arch debug-files rpaths"

# x86
COMPATIBLE_MACHINE_swi-virt-x86 = "swi-virt-x86"

KMACHINE_swi-virt-x86 = "qemux86"
KBRANCH_swi-virt-x86 = "${KBRANCH:qemux86}"

KERNEL_FEATURES:append:swi-virt-x86 = "${KERNEL_FEATURES:append:qemux86}"

SRCREV_machine_swi-virt-x86 = "${SRCREV_machine:qemux86}"

# arm
COMPATIBLE_MACHINE_swi-virt-arm = "swi-virt-arm"

KMACHINE_swi-virt-arm = "qemuarm"
KBRANCH_swi-virt-arm = "${KBRANCH:qemuarm}"

SRCREV_machine_swi-virt-arm = "${SRCREV_machine:qemuarm}"

# IMA
DEPENDS += "ima-support-tools-native"

do_configure:append() {
    # Add ".system" public cert into kernel build area.
    if [ "x${IMA_BUILD}" == "xtrue" ]; then

        echo "IMA: Copying ${IMA_LOCAL_CA_X509} to ${B} ..."

        # Convert certificate to PEM format
        if [[ "${IMA_LOCAL_CA_X509}" != *.pem ]]; then
            openssl x509 -inform der -in "${IMA_LOCAL_CA_X509}" -out "${B}/ima-system.pem" -outform pem
        else
            cp -f "${IMA_LOCAL_CA_X509}" "${B}/ima-system.pem"
        fi

        # Update config
        echo 'CONFIG_SYSTEM_TRUSTED_KEYS="ima-system.pem"' >> ${B}/.config

        # Reconfigure
        ${KERNEL_CONFIG_COMMAND}
    fi
}

# Needed to build extract-cert.c
DEPENDS += "openssl-native"
KERNEL_EXTRA_ARGS = " STAGING_LIBDIR_NATIVE=${STAGING_LIBDIR_NATIVE} STAGING_INCDIR_NATIVE=${STAGING_INCDIR_NATIVE} "

do_patch:append() {
    if ! grep "/openssl" "${S}/scripts/Makefile"; then
        echo 'HOST_EXTRACFLAGS += -I$(STAGING_INCDIR_NATIVE)/'        >> "${S}/scripts/Makefile"
        echo 'HOST_EXTRACFLAGS += -I$(STAGING_INCDIR_NATIVE)/openssl' >> "${S}/scripts/Makefile"
        echo 'HOST_EXTRACFLAGS += -L$(STAGING_LIBDIR_NATIVE)/'        >> "${S}/scripts/Makefile"
    fi

    # Patch kernel sources to add 'modpost' back to 'make scripts'
    # This partially reverts https://patchwork.kernel.org/patch/10690901/
    if ! grep "+= mod" "${S}/scripts/Makefile"; then
        ## Re-insert asm-generic and $(autoksyms_h) (gcc-plugins doesn't exist as this anymore)
        sed -i 's/scripts: scripts_basic scripts_dtc/scripts: scripts_basic scripts_dtc asm-generic $(autoksyms_h)/' "${S}/Makefile"
        ## Re-insert dependency from scripts to scripts/mod
        sed -i '/+= genksyms/a subdir-y                     += mod' "${S}/scripts/Makefile"
    fi
}

# The LD_LIBRARY_PATH variable is not set when building kernel.
# Work around this by adding the build's sysroot libraries to LD_LIBRARY_PATH.
kernel_do_compile:prepend(){
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${STAGING_LIBDIR_NATIVE}:${STAGING_LIBDIR_NATIVE}/../../lib
}

do_install:prepend(){
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${STAGING_LIBDIR_NATIVE}:${STAGING_LIBDIR_NATIVE}/../../lib
}

do_install:append() {
    kernel_src_install
}
