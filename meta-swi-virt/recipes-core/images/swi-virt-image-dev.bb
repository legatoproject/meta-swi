require swi-virt-image.inc

IMAGE_FEATURES += "dev-pkgs"

# Add some things for dev & system intg
IMAGE_INSTALL_append = " cmake"
IMAGE_INSTALL_append = " libopkg"
