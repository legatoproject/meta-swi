require recipes-kernel/linux-msm/linux-msm.inc

#inherit sdllvm

# if is TARGET_KERNEL_ARCH is set inherit qtikernel-arch to compile for that arch.
inherit ${@bb.utils.contains('TARGET_KERNEL_ARCH', 'aarch64', 'qtikernel-arch', '', d)}

COMPATIBLE_MACHINE = "(qcs40x|sdxprairie|sdmsteppe|swi-sdx55|swi-mdm9x28)"
KERNEL_IMAGEDEST = "boot"

DEPENDS += "dtc-native"
#DEPENDS += " llvm-arm-toolchain-native"

LDFLAGS:aarch64 = "-O1 --hash-style=gnu --as-needed"
TARGET_CXXFLAGS += "-Wno-format"
EXTRA_OEMAKE:append += "INSTALL_MOD_STRIP=1"

# Determine linux version from sources
def determine_linux_version(d):
    repo_dir = d.getVar('LINUX_REPO_DIR', True)
    makefile_path = os.path.join(repo_dir, "Makefile")
    if not os.path.exists(makefile_path):
        raise Exception("Kernel Makefile doesn't exist at %s" % makefile_path)

    import re
    v = []
    with open(makefile_path) as f:
        r = re.compile("(VERSION|PATCHLEVEL|SUBLEVEL) = (\d+)")
        for line in f:
            m = r.match(line)
            if not m:
                continue

            v.append(m.group(2))
            if m.group(1) == "SUBLEVEL":
                break

    if len(v) != 3:
        raise Exception("Error while parsing Kernel Makefile %s: "
                        "%d sub-version(s) found instead of 3" % (makefile_path, len(v)))

    return ".".join(v)

LINUX_VERSION ?= "${@determine_linux_version(d)}"
PV = "${LINUX_VERSION}"
PR = "r1"

do_compile () {
    oe_runmake CC="${KERNEL_CC}" LD="${KERNEL_LD}" ${KERNEL_EXTRA_ARGS} $use_alternate_initrd
}

do_shared_workdir:append () {
        cp Makefile $kerneldir/
        cp -fR usr $kerneldir/

        cp include/config/auto.conf $kerneldir/include/config/auto.conf

        if [ -d arch/${ARCH}/include ]; then
                mkdir -p $kerneldir/arch/${ARCH}/include/
                cp -fR arch/${ARCH}/include/* $kerneldir/arch/${ARCH}/include/
        fi

        if [ -d arch/${ARCH}/boot ]; then
                mkdir -p $kerneldir/arch/${ARCH}/boot/
                cp -fR arch/${ARCH}/boot/* $kerneldir/arch/${ARCH}/boot/
        fi

        if [ -d scripts ]; then
            for i in \
                scripts/basic/bin2c \
                scripts/basic/fixdep \
                scripts/conmakehash \
                scripts/dtc/dtc \
                scripts/kallsyms \
                scripts/kconfig/conf \
                scripts/mod/mk_elfconfig \
                scripts/mod/modpost \
                scripts/recordmcount \
                scripts/sign-file \
                scripts/sortextable;
            do
                if [ -e $i ]; then
                    mkdir -p $kerneldir/`dirname $i`
                    cp $i $kerneldir/$i
                fi
            done
        fi

        cp ${STAGING_KERNEL_DIR}/scripts/gen_initramfs_list.sh $kerneldir/scripts/

        # Copy zImage into deplydir for boot.img creation
        install -m 0644 ${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE} ${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}

        # Generate kernel headers
        oe_runmake_call -C ${STAGING_KERNEL_DIR} ARCH=${ARCH} CC="${KERNEL_CC}" LD="${KERNEL_LD}" headers_install O=${STAGING_KERNEL_BUILDDIR}
}

do_shared_workdir[dirs] = "${DEPLOY_DIR_IMAGE}"

INHIBIT_PACKAGE_STRIP = "1"
