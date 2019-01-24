require mdm9x40-image-minimal.bb

DESCRIPTION = "A baseline image just capable of allowing SWI mdm9x40 to boot and \
is suitable for development work."

IMAGE_FEATURES += "dev-pkgs debug-tweaks tools-profile tools-debug"

PR = "${INC_PR}.0"

VALGRIND_arm = "valgrind"

IMAGE_INSTALL_append = " mtd-utils"
IMAGE_INSTALL_append = " mtd-utils-ubifs"
IMAGE_INSTALL_append = " i2c-tools"
IMAGE_INSTALL_append = " tcpdump"
IMAGE_INSTALL_append = " iperf3"
IMAGE_INSTALL_append = " dosfstools"
IMAGE_INSTALL_append = " e2fsprogs"
IMAGE_INSTALL_append = " e2fsprogs-mke2fs"
IMAGE_INSTALL_append = " openssh-scp"
IMAGE_INSTALL_append = " openssh-ssh"
IMAGE_INSTALL_append = " usbutils"
IMAGE_INSTALL_append = " ethtool"
IMAGE_INSTALL_append = " rpm"
IMAGE_INSTALL_append = " iproute2"
IMAGE_INSTALL_append = " iptables"
IMAGE_INSTALL_append = " openssl"
IMAGE_INSTALL_append = " wireless-tools"
IMAGE_INSTALL_append = " ppp"
IMAGE_INSTALL_append = " ppp-dialin"
IMAGE_INSTALL_append = " wpa-supplicant"
IMAGE_INSTALL_append = " hostapd"
IMAGE_INSTALL_append = " hostap-conf"
IMAGE_INSTALL_append = " hostap-utils"
IMAGE_INSTALL_append = " userspace-test"
IMAGE_INSTALL_append = " agent-proxy"
IMAGE_INSTALL_append = " kernel-test"
IMAGE_INSTALL_append = " kernel-modules"
IMAGE_INSTALL_append = " ltrace"
IMAGE_INSTALL_append = " lmbench"
IMAGE_INSTALL_append = " valgrind"

prepare_ubi() {
    :
}
