inherit swi-image-minimal

# Add timezone related packages
IMAGE_INSTALL:append = " tzdata"
IMAGE_INSTALL:append = " tzone-utils"