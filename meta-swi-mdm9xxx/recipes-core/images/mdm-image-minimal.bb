inherit swi-image-minimal

# Add timezone related packages
IMAGE_INSTALL_append = " tzdata"
IMAGE_INSTALL_append = " tzone-utils"