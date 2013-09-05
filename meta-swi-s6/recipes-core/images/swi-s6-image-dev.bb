require swi-s6-image-minimal.bb

DESCRIPTION = "A baseline image just capable of allowing SWI S6 to boot and \
is suitable for development work."

IMAGE_FEATURES += "dev-pkgs debug-tweaks tools-profile tools-debug"

IMAGE_INSTALL += "mtd-utils"
IMAGE_INSTALL += "i2c-tools"
IMAGE_INSTALL += "tcpdump"
IMAGE_INSTALL += "iperf"
IMAGE_INSTALL += "dosfstools"
IMAGE_INSTALL += "e2fsprogs"
IMAGE_INSTALL += "e2fsprogs-mke2fs"
IMAGE_INSTALL += "openssh-scp"
IMAGE_INSTALL += "openssh-ssh"
IMAGE_INSTALL += "usbutils"
IMAGE_INSTALL += "ltrace"
IMAGE_INSTALL += "rpm"
IMAGE_INSTALL += "ethtool"
IMAGE_INSTALL += "kernel-modules"
IMAGE_INSTALL += "kernel-test"
IMAGE_INSTALL += "userspace-test"
IMAGE_INSTALL += "agent-proxy"
IMAGE_INSTALL += "setserial"
IMAGE_INSTALL += "lrzsz"
IMAGE_INSTALL += "lmbench"
