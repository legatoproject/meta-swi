require mdm9x28-image-minimal.bb

DESCRIPTION = "A baseline image just capable of allowing SWI mdm9x28 to boot and \
is suitable for development work."

IMAGE_FEATURES += "dev-pkgs debug-tweaks tools-profile tools-debug"

PR = "${INC_PR}.0"

VALGRIND:arm = "valgrind"

IMAGE_INSTALL:append = " mtd-utils"
IMAGE_INSTALL:append = " mtd-utils-ubifs"
IMAGE_INSTALL:append = " i2c-tools"
IMAGE_INSTALL:append = " tcpdump"
IMAGE_INSTALL:append = " iperf3"
IMAGE_INSTALL:append = " dosfstools"
IMAGE_INSTALL:append = " e2fsprogs"
IMAGE_INSTALL:append = " e2fsprogs-mke2fs"
IMAGE_INSTALL:append = " openssh-scp"
IMAGE_INSTALL:append = " openssh-ssh"
IMAGE_INSTALL:append = " usbutils"
IMAGE_INSTALL:append = " ethtool"
IMAGE_INSTALL:append = " rpm"
IMAGE_INSTALL:append = " iproute2"
IMAGE_INSTALL:append = " iptables"
IMAGE_INSTALL:append = " openssl"
IMAGE_INSTALL:append = " wireless-tools"
IMAGE_INSTALL:append = " ppp"
IMAGE_INSTALL:append = " ppp-dialin"
IMAGE_INSTALL:append = " wpa-supplicant"
IMAGE_INSTALL:append = " hostapd"
IMAGE_INSTALL:append = " hostap-conf"
IMAGE_INSTALL:append = " hostap-utils"
IMAGE_INSTALL:append = " userspace-test"
IMAGE_INSTALL:append = " agent-proxy"
IMAGE_INSTALL:append = " kernel-test"
IMAGE_INSTALL:append = " kernel-modules"
IMAGE_INSTALL:append = " ltrace"
IMAGE_INSTALL:append = " lmbench"
IMAGE_INSTALL:append = " valgrind"

prepare_ubi() {
    :
}
