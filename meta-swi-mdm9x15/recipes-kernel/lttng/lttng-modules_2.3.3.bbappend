FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"


SRCREV = "789fd1d06d07aeb9a403bdce1b3318560cfc6eca"

COMPATIBLE_HOST = '(x86_64|i.86|powerpc|aarch64|mips|arm).*-linux'
SRC_URI = "git://git.lttng.org/lttng-modules.git;branch=stable-2.5 \
         file://lttng-modules-replace-KERNELDIR-with-KERNEL_SRC.patch \
         file://Update-compaction-instrumentation-to-3.16-kernel.patch \
         file://Update-vmscan-instrumentation-to-3.16-kernel.patch \
         file://Fix-noargs-probes-should-calculate-alignment-and-eve.patch \
         file://Update-statedump-to-3.17-nsproxy-locking.patch \
         file://Update-kvm-instrumentation-compile-on-3.17-rc1.patch \
         file://fix_build_with_v3.17_kernel.patch \
         "
export INSTALL_MOD_DIR="kernel/lttng-modules"
export KERNEL_SRC="${STAGING_KERNEL_DIR}"

S = "${WORKDIR}/git"

do_install_append() {
   # Delete empty directories to avoid QA failures if no modules were built
   find ${D}/lib -depth -type d -empty -exec rmdir {} \;
}

