require mdm9x15-image-minimal.bb

DESCRIPTION = "A baseline image just capable of allowing SWI mdm9x15 to boot and \
is suitable for development work."

IMAGE_FEATURES += "dev-pkgs debug-tweaks tools-profile tools-debug"

PR = "${INC_PR}.0"

VALGRIND_arm = "valgrind"

IMAGE_INSTALL += "mtd-utils"
IMAGE_INSTALL += "mtd-utils-ubifs"
IMAGE_INSTALL += "i2c-tools"
IMAGE_INSTALL += "tcpdump"
IMAGE_INSTALL += "iperf"
IMAGE_INSTALL += "dosfstools"
IMAGE_INSTALL += "e2fsprogs"
IMAGE_INSTALL += "e2fsprogs-mke2fs"
IMAGE_INSTALL += "openssh-scp"
IMAGE_INSTALL += "openssh-ssh"
IMAGE_INSTALL += "usbutils"
IMAGE_INSTALL += "ethtool"
IMAGE_INSTALL += "rpm"
IMAGE_INSTALL += "iproute2"
IMAGE_INSTALL += "iptables"
IMAGE_INSTALL += "openssl"
IMAGE_INSTALL += "wireless-tools"
IMAGE_INSTALL += "ppp"
IMAGE_INSTALL += "ppp-dialin"
IMAGE_INSTALL += "wpa-supplicant"
IMAGE_INSTALL += "hostap-daemon"
IMAGE_INSTALL += "hostap-conf"
IMAGE_INSTALL += "hostap-utils"
IMAGE_INSTALL += "userspace-test"
IMAGE_INSTALL += "agent-proxy"
IMAGE_INSTALL += "kernel-test"
IMAGE_INSTALL += "kernel-modules"
IMAGE_INSTALL += "ltrace"
IMAGE_INSTALL += "lmbench"
IMAGE_INSTALL += "valgrind"

prepare_ubi() {
    :
}
