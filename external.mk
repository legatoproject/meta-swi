self := $(lastword $(MAKEFILE_LIST))
self_dir:= $(dir $(self))

include $(self_dir)meta-swi/common.mk

# Replaces this Makefile by a symlink to external.mk
$(shell if ! test -h $(self); then rm -f $(self) && ln -s $(self_dir)meta-swi/external.mk $(self); fi)

ifneq (,$(wildcard $(PWD)/legato/3rdParty/ima-support-tools/))
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_DIR=$(PWD)/legato/3rdParty/"
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_REPO=file://ima-support-tools"
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_NAME=ima-support-tools"
endif

# Machine: swi-mdm9x15

ifeq ($(MACH),mdm9x15)
  KBRANCH_mdm9x15 := $(shell git --git-dir=kernel/.git branch | grep -oe 'standard/.*')
  KMETA_mdm9x15 := $(shell git --git-dir=kernel/.git branch | grep -oe 'meta-.*')

  MACH_ARGS += --recipe-args=KBRANCH_DEFAULT_MDM9X15=${KBRANCH_mdm9x15} \
               --recipe-args=KMETA_DEFAULT_MDM9X15=${KMETA_mdm9x15}
endif

## extras needed for building

POKY_VERSION ?= bda51ee7821de9120f6f536fcabe592f2a0c8a37
META_OE_VERSION ?= 8e6f6e49c99a12a0382e48451f37adac0181362f

poky:
	git clone git://git.yoctoproject.org/poky
	cd poky && git checkout ${POKY_VERSION}

meta-openembedded:
	git clone git://git.openembedded.org/meta-openembedded
	cd meta-openembedded && git checkout ${META_OE_VERSION}

.PHONY: prepare
prepare: poky meta-openembedded
