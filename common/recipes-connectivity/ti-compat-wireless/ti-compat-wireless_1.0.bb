SUMMARY = "TI WL18XX Wifi driver and user-land tools."

HOMEPAGE = "http://www.ti.com"

LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/GPL-2.0;md5=801f80980d171dd6425610833a22dbe6"

SRCREV = "de2429e25228552c5d0cb21a93707436cb8602f1"
SRC_URI = "git://git.ti.com/wilink8-wlan/build-utilites.git;protocol=git \
           file://wl18xx-conf.bin \
           file://0001-wlcore-ELP-timeout.patch"

S = "${WORKDIR}/git"

DEPENDS += "virtual/kernel"
DEPENDS += "openssl"
DEPENDS += "libgcrypt"

# This release R8.5 is mandatory for kernel = 3.x.y and < 4.x.y
TIWIFI_RELEASE ?= "R8.5"

PR = "r0"

TIWIFI_DEFAULT_AP_NAME ?= "SierraWP85"

do_patch() {
    cd ${S}
    sed -i 's,^[ \t][ \t]*build_all,#\t\tbuild_all,' build_wl18xx.sh
    sed -i 's,\+="-,\+=" -,g;s,\+=-,\+=" "-,g' build_wl18xx.sh
}

do_configure() {
    cd ${S}
    cp setup-env.sample setup-env
    sed -i 's,TOOLCHAIN_PATH=DEFAULT,TOOLCHAIN_PATH='`which "${OBJDUMP}" | sed 's/'"${OBJDUMP}"'//'`',' setup-env
    sed -i 's,KERNEL_PATH=DEFAULT,KERNEL_PATH='"${STAGING_KERNEL_DIR}"',' setup-env
    sed -i 's,CROSS_COMPILE=.*$,CROSS_COMPILE='"${TARGET_SYS}-"',' setup-env
    PATH=.:$PATH ./build_wl18xx.sh init
    PATH=.:$PATH CFLAGS= CC= ./build_wl18xx.sh update ${TIWIFI_RELEASE}
    (cd src/driver; patch -p1 <${WORKDIR}/0001-wlcore-ELP-timeout.patch)
    sed -i 's,-Werror=date-time,-Wnoerror=date-time,' ${STAGING_KERNEL_DIR}/Makefile
    yes | ./verify_kernel_config.sh "${STAGING_KERNEL_DIR}"/.config || true
}

do_compile() {
    cd ${S}
    export PATH=.:$PATH

    # CC CFLAGS LDFLAGS LIBS and PKG_CONFIG_SYSROOT_DIR varibles need to be overwritten
    # before calling build_wl18xx.sh because of some disturbances between Yocto and TI SDK
    CC= ./build_wl18xx.sh firmware

    # CC is set to native gcc to build the configuration tool for the Linux kernel
    # Compile, install and deploy to ROOTFS the TI wlxxxx drivers from TI build tree instead
    # of them provided in the Linux-3.14 kernel tree
    CC=gcc ./build_wl18xx.sh modules

    CC= ./build_wl18xx.sh libnl
    LDFLAGS= \
        LIBS=" -L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" \
        NLLIBNAME=libnl-3.0 \
        CC= \
        ./build_wl18xx.sh hostapd
    PKG_CONFIG_SYSROOT_DIR= \
        CFLAGS="-DCONFIG_LIBNL30 -I"${S}"/fs/include/libnl3" \
        LDFLAGS= \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
        ./build_wl18xx.sh iw
    LDFLAGS= \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
        ./build_wl18xx.sh hostapd
    LDFLAGS= \
        CFLAGS= \
        CC= \
        ./build_wl18xx.sh wpa_supplicant
    LDFLAGS= \
        CFLAGS="-DCONFIG_LIBNL32 -I"${S}"/fs/include/libnl3" \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
        ./build_wl18xx.sh utils
    LDFLAGS= \
        CFLAGS="-DCONFIG_LIBNL32 -I"${S}"/fs/include/libnl3" \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
    ./build_wl18xx.sh openssl
    PKG_CONFIG_SYSROOT_DIR= \
        LDFLAGS= \
        CFLAGS="-DCONFIG_LIBNL32 -I"${S}"/fs/include/libnl3" \
        LIBS="-L"${S}"/fs/lib -lnl-genl-3 -lnl-3 -lpthread -lm" NLLIBNAME=libnl-3.0 \
        CC= \
    ./build_wl18xx.sh crda
    (cd ${S}/src/wireless_regdb; \
    PKG_CONFIG_SYSROOT_DIR= \
        LDFLAGS= \
        CC= \
        WHOAMI="sierrawireless" \
        DESTDIR=${S}"/fs" \
        make install)
    install -m 755 -d ${S}/fs/etc/udev/rules.d
    install -m 644 ${S}/src/crda/udev/85-regulatory.rules ${S}/fs/etc/udev/rules.d/
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
    install -m 0644 ${S}/fs/usr/lib/libreg.so ${D}/lib
    install -m 0644 ${S}/fs/usr/lib/crda/regulatory.bin ${D}/usr/lib/crda/
    install -m 0644 ${S}/fs/usr/lib/crda/pubkeys/* ${D}/etc/wireless-regdb/pubkeys/
    cp -a ${S}/fs/sbin ${D}/
    cp -a ${S}/fs/usr/local/bin ${D}/
    cp -a ${S}/fs/usr/local/sbin ${D}/
    cp -a ${WORKDIR}/wl18xx-conf.bin ${D}/lib/firmware/ti-connectivity/
}

INSANE_SKIP_${PN} = "dev-deps"

FILES_${PN}-dbg += "usr/sbin/wlconf/.debug usr/lib/crda/.debug"

FILES_${PN} += "lib usr/lib"
