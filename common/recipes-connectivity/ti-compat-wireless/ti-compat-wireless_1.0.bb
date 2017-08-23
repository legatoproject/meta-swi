SUMMARY = "TI WL18XX Wifi driver and user-land tools."

HOMEPAGE = "http://www.ti.com"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

SRC_URI = "http://downloads.sierrawireless.com/yocto/ti-compat-wireless-8.5.tar.bz2 \
           file://wl18xx-conf.bin \
           file://gentree.py \
           file://swi_build_wl18xx.sh"

TI_KERNEL_DIR = "${WORKDIR}/kernel-source"

SRC_URI[md5sum] = "e4f8572b46ee101eb39e5b091aba0856"
SRC_URI[sha256sum] = "60ddaaf2a9aab9fad475bcd1a5d837eb840c2e93332b7d1d11e9843dece88cd2"

S = "${WORKDIR}/ti-compat-wireless"

do_configure[depends] += "linux-yocto:do_populate_sysroot"

DEPENDS += "openssl"
DEPENDS += "libgcrypt"
DEPENDS += "python-m2crypto-native"
DEPENDS += "python-native"

# This release R8.5 is mandatory for kernel = 3.x.y and < 4.x.y
TIWIFI_RELEASE ?= "R8.5"

PR = "r0"

TIWIFI_DEFAULT_AP_NAME ?= "SierraWP85"

inherit module-base update-alternatives

# The pktloc and classid files clash clash against libnl-3 in Yocto,

ALTERNATIVE_PRIORITY = "100"
ALTERNATIVE_${PN} = "pktloc classid"

ALTERNATIVE_LINK_NAME[pktloc] = "/etc/libnl/pktloc"
ALTERNATIVE_TARGET[pktloc] = "/etc/libnl/pktloc.${PN}"

ALTERNATIVE_LINK_NAME[classid] = "/etc/libnl/classid"
ALTERNATIVE_TARGET[classid] = "/etc/libnl/classid.${PN}"

addtask make_scripts after do_patch before do_compile
do_make_scripts[lockfiles] = "${TMPDIR}/kernel-scripts.lock"
do_make_scripts[deptask] = "do_populate_sysroot"

do_patch() {
    cd ${S}
    cp -pv ${WORKDIR}/swi_build_wl18xx.sh .
    cp -pv ${WORKDIR}/gentree.py src/backports/
    sed -i "s,TIWIFI_RELEASE,${TIWIFI_RELEASE},g" src/backports/gentree.py
}

do_configure() {
    cd ${S}
    cp setup-env.sample setup-env

    # We copy the entire kernel tree and add the .config into the copy;
    # ti-compat-wireless needs a kernel tree with a .config in it.
    mkdir -p ${TI_KERNEL_DIR}
    cp -a ${STAGING_KERNEL_DIR}/. ${TI_KERNEL_DIR}/.
    cp ${KBUILD_OUTPUT}/.config ${TI_KERNEL_DIR}

    sed -i 's,TOOLCHAIN_PATH=DEFAULT,TOOLCHAIN_PATH='`which "${OBJDUMP}" | sed 's/'"${OBJDUMP}"'//'`',' setup-env
    sed -i 's,KERNEL_PATH=DEFAULT,KERNEL_PATH='"${TI_KERNEL_DIR}"',' setup-env
    sed -i 's,CROSS_COMPILE=.*$,CROSS_COMPILE='"${TARGET_SYS}-"',' setup-env
    PATH=.:$PATH ./swi_build_wl18xx.sh init
    PATH=.:$PATH CFLAGS= CC= ./swi_build_wl18xx.sh update ${TIWIFI_RELEASE}
    sed -i 's,WL1271_WAKEUP_TIMEOUT 500,WL1271_WAKEUP_TIMEOUT 2500,' src/driver/drivers/net/wireless/ti/wlcore/ps.c
    sed -i 's,-Werror=date-time,-Wnoerror=date-time,' ${TI_KERNEL_DIR}/Makefile
    yes | ./verify_kernel_config.sh "${TI_KERNEL_DIR}"/.config || true
}

do_compile() {
    cd ${S}
    export PATH=.:$PATH
    export PYTHONPATH=${STAGING_LIBDIR_NATIVE}/python${PYTHON_BASEVERSION}/site-packages

    # CC CFLAGS LDFLAGS LIBS and PKG_CONFIG_SYSROOT_DIR varibles need to be overwritten
    # before calling build_wl18xx.sh because of some disturbances between Yocto and TI SDK
    CC= ./swi_build_wl18xx.sh firmware

    # CC is set to native gcc to build the configuration tool for the Linux kernel
    # Compile, install and deploy to ROOTFS the TI wlxxxx drivers from TI build tree instead
    # of them provided in the Linux-3.14 kernel tree
    CC=gcc ./swi_build_wl18xx.sh modules

    export YOCTO_CC=$CC
    export YOCTO_LDFLAGS=${LDFLAGS/ -Wl,--as-needed/}

    CC= ./swi_build_wl18xx.sh libnl
    LDFLAGS= \
        LIBS=" -L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" \
        NLLIBNAME=libnl-3.0 \
        CC= \
        ./swi_build_wl18xx.sh hostapd
    PKG_CONFIG_SYSROOT_DIR= \
        CFLAGS="-DCONFIG_LIBNL30 -I"${S}"/fs/include/libnl3" \
        LDFLAGS= \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
        ./swi_build_wl18xx.sh iw
    LDFLAGS= \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
        ./swi_build_wl18xx.sh hostapd
    LDFLAGS= \
        CFLAGS= \
        CC= \
        ./swi_build_wl18xx.sh wpa_supplicant
    LDFLAGS= \
        CFLAGS="-DCONFIG_LIBNL32 -I"${S}"/fs/include/libnl3" \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
        ./swi_build_wl18xx.sh utils
    LDFLAGS= \
        CFLAGS="-DCONFIG_LIBNL32 -I"${S}"/fs/include/libnl3" \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
    ./swi_build_wl18xx.sh openssl
    PKG_CONFIG_SYSROOT_DIR= \
        LDFLAGS= \
        CFLAGS="-DCONFIG_LIBNL32 -I"${S}"/fs/include/libnl3" \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
    ./swi_build_wl18xx.sh crda
    (cd ${S}/src/wireless_regdb; \
    PKG_CONFIG_SYSROOT_DIR= \
        LDFLAGS= \
        CC= \
        WHOAMI="sierrawireless" \
        DESTDIR=${S}"/fs" \
        make install)
}

do_install() {
    install -m 0755 -d ${D}/etc
    install -m 0755 -d ${D}/lib
    install -m 0755 -d ${D}/usr
    install -m 0755 -d ${D}/usr/lib/crda
    cp -a ${S}/fs/etc ${D}/
    sed -i 's/wlan1/wlan0/' ${D}/etc/hostapd.conf
    sed -i 's/^ssid=.*$/ssid='${TIWIFI_DEFAULT_AP_NAME}'/' ${D}/etc/hostapd.conf
    cp -a ${S}/fs/lib/modules ${D}/lib/
    cp -a ${S}/fs/lib/firmware ${D}/lib/
    cp -a ${S}/fs/usr/bin ${D}/usr
    cp -a ${S}/fs/usr/sbin ${D}/usr
    install -m 0644 ${S}/fs/usr/lib/libreg.so ${D}/lib/libreg.so.0
    ln -s libreg.so.0 ${D}/lib/libreg.so
    install -m 0644 ${S}/fs/usr/lib/crda/regulatory.bin ${D}/usr/lib/crda/
    install -m 0644 ${S}/fs/usr/lib/crda/pubkeys/* ${D}/etc/wireless-regdb/pubkeys/
    cp -a ${S}/fs/sbin ${D}/
    cp -a ${S}/fs/usr/local/bin ${D}/
    cp -a ${S}/fs/usr/local/sbin ${D}/
    cp -a ${WORKDIR}/wl18xx-conf.bin ${D}/lib/firmware/ti-connectivity/
    chown -R --reference=${D}/usr ${D}
    chmod -R u+rwX,go-w ${D}

    # Move libnl-3 clashing files
    mv ${D}/etc/libnl/{pktloc,pktloc.${PN}}
    mv ${D}/etc/libnl/{classid,classid.${PN}}
}

INSANE_SKIP_${PN} = "dev-deps"

FILES_${PN}-dbg += "usr/sbin/wlconf/.debug usr/lib/crda/.debug"

FILES_${PN} += "lib usr/lib"
