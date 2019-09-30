self := $(lastword $(MAKEFILE_LIST))
self_dir:= $(dir $(self))

include $(self_dir)meta-swi/common.mk

# Replaces this Makefile by a symlink to external.mk
$(shell if ! test -h $(self); then rm -f $(self) && ln -s $(self_dir)meta-swi/repo.mk $(self); fi)

APPS_DIR ?= $(firstword $(wildcard $(PWD)/mdm*[0-9]/apps_proc))
ifneq ($(wildcard $(PWD)/mdm*[0-9]/common),)
  DEFAULT_MDM_BUILD := src
  MACH ?= $(patsubst $(PWD)/%/apps_proc,%,$(APPS_DIR))
else ifneq ($(wildcard $(PWD)/sdx55/common),)
  DEFAULT_MDM_BUILD := src
  MACH ?= sdx55
  APPS_DIR = $(firstword $(wildcard $(PWD)/sdx55/SDX55_apps/apps_proc))
endif

# Try to get product name from manifest.xml
ifeq ($(PROD),)
  PROD := $(shell sed -nr '/product name/{s/.*name="(.*)".*/\1/;p}' $(shell pwd)/.repo/manifest.xml)
endif

ifneq (,$(wildcard $(PWD)/legato/3rdParty/ima-support-tools/))
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_REPO=git://$(PWD)/legato/3rdParty/ima-support-tools/.git;protocol=file;usehead=1"
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_REV=\$${AUTOREV}"
endif

# Machine:

include $(wildcard $(MACH)/fw.mk)

# Machine: swi-mdm9x15

ifeq (mdm9x15,$(MACH))

  # Create branches KBRANCH / KMETA in kernel

  KBRANCH_mdm9x15_REV := $(shell cd kernel && git rev-parse HEAD | cut -c 1-10 -)
  KMETA_mdm9x15_REV := $(shell cd kernel-meta && git rev-parse HEAD | cut -c 1-10 -)

  ifndef KBRANCH_mdm9x15
    KBRANCH_mdm9x15 := $(shell git --git-dir=kernel/.git rev-parse --symbolic-full-name m/master | grep -v 'm/master' | grep -v tags | sed 's^refs/remotes/[-_a-z0-9]*/^^gi')
    ifeq ($(KBRANCH_mdm9x15),)
      KBRANCH_mdm9x15 := $(shell git --git-dir=kernel/.git branch -r --contains $(KBRANCH_mdm9x15_REV) | grep -v 'm/master' | sed 's!^ *[-_a-z0-9]*/!!gi' | head -1)
      ifeq ($(KBRANCH_mdm9x15),)
        KBRANCH_mdm9x15 := "standard/swi-mdm9x15-unknown"
      endif
    endif
  endif

  ifndef KMETA_mdm9x15
    KMETA_mdm9x15 := $(shell git --git-dir=kernel-meta/.git rev-parse --symbolic-full-name m/master | grep -v 'm/master' | grep -v tags | sed 's^refs/remotes/[-_a-z0-9]*/^^gi')
    ifeq ($(KMETA_mdm9x15),)
      KMETA_mdm9x15 := $(shell git --git-dir=kernel-meta/.git branch -r --contains $(KMETA_mdm9x15_REV) | grep -v 'm/master' | sed 's!^ *[-_a-z0-9]*/!!gi' | head -1)
      ifeq ($(KMETA_mdm9x15),)
        KMETA_mdm9x15 := "meta-yocto-unknown"
      endif
    endif
  endif

  KBRANCH_mdm9x15_CURRENT_REV := $(shell cd kernel && git show-ref -s refs/heads/${KBRANCH_mdm9x15} | cut -c 1-10 -)
  KMETA_mdm9x15_CURRENT_REV := $(shell cd kernel && git show-ref -s refs/heads/${KMETA_mdm9x15} | cut -c 1-10 -)

  KBRANCH_mdm9x15_BRIEF := $(shell git --git-dir=kernel/.git log -1 --pretty=oneline | sed "s/'//g")
  KMETA_mdm9x15_BRIEF := $(shell git --git-dir=kernel-meta/.git log -1 --pretty=oneline | sed "s/'//g")

  MACH_ARGS += --recipe-args=KBRANCH_DEFAULT_MDM9X15=${KBRANCH_mdm9x15} \
               --recipe-args=KMETA_DEFAULT_MDM9X15=${KMETA_mdm9x15}

  PREPARE_TASKS += kernel_branches

.PHONY: kernel_branches
kernel_branches:
	@echo 'kernel KBRANCH_mdm9x15 (${KBRANCH_mdm9x15}): ${KBRANCH_mdm9x15_BRIEF}'
	@if ! ( cd kernel && git branch |grep ${KBRANCH_mdm9x15} > /dev/null ); then \
		echo "Create dev kernel branch ${KBRANCH_mdm9x15}" ; \
		cd kernel && git branch ${KBRANCH_mdm9x15} ${KBRANCH_mdm9x15_REV} ; \
	fi
	@if [ "${KBRANCH_mdm9x15_CURRENT_REV}" != "${KBRANCH_mdm9x15_REV}" ]; then \
		echo "=> Updating dev kernel branch ${KBRANCH_mdm9x15}: ${KBRANCH_mdm9x15_REV}" ; \
		cd kernel && git branch -f ${KBRANCH_mdm9x15} ${KBRANCH_mdm9x15_REV} ; \
	fi
	@echo "kernel KMETA_mdm9x15 (${KMETA_mdm9x15}): ${KMETA_mdm9x15_BRIEF}"
	@if ! ( cd kernel && git branch |grep ${KMETA_mdm9x15} > /dev/null ); then \
		echo "Create dev kernel meta branch ${KMETA_mdm9x15}: ${KMETA_mdm9x15_REV}" ; \
		cd kernel && git branch ${KMETA_mdm9x15} ${KMETA_mdm9x15_REV} ; \
	fi
	@if [ "${KMETA_mdm9x15_CURRENT_REV}" != "${KMETA_mdm9x15_REV}" ]; then \
		echo "=> Updating dev kernel meta branch ${KMETA_mdm9x15}: ${KMETA_mdm9x15_REV}" ; \
		cd kernel && git branch -f ${KMETA_mdm9x15} ${KMETA_mdm9x15_REV} ; \
	fi
	@if ! ( cd kernel && git branch | grep master > /dev/null ); then \
		echo "Create local master branch" ; \
		cd kernel && git branch master `git remote | head -1`/master ; \
	fi

endif

.PHONY: prepare
prepare: $(PREPARE_TASKS)

QEMU_ARGS ?=
ifeq ($(QEMU),1)
  QEMU_ARGS := --enable-qemu
endif

COMMON_SRC := \
				$(COMMON_MACH) \
				${QEMU_ARGS} \
				--build-dir=build_src

ifeq ($(PROPRIETARY_BUILD),1)
  COMMON_SRC += --enable-prop-src --apps-proc-dir=$(APPS_DIR) --firmware-version=$(FW_VERSION)
endif

image_src: prepare
	$(COMMON_SRC)


toolchain_src: prepare
	$(COMMON_SRC) --build-toolchain


dev_src: prepare
	$(COMMON_SRC) --cmdline-mode


## binary layer generation

BIN_LAYER_ARGS := --swi-matchine-type=$(MACH)
ifneq ($(PROD),)
  BIN_LAYER_ARGS += --product=$(PROD)
endif

binary_layer:
	$(PWD)/meta-swi-extras/create_bin_layer.sh \
		-b $(PWD)/build_src/ \
		-o $(PWD)/build_src/binary_layer/ \
		$(BIN_LAYER_ARGS)

