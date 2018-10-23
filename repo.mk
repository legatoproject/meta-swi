# Set number of threads
NUM_THREADS ?= 9

# Set workspace directory
DEFAULT_MDM_BUILD := bin
APPS_DIR ?= $(firstword $(wildcard $(PWD)/mdm*[0-9]/apps_proc))
ifneq ($(wildcard $(PWD)/mdm*[0-9]/common),)
  DEFAULT_MDM_BUILD := src
endif

# Machine architecture
# Guess the architecture and product based on the availability of proprietary binaries.
# If binaries are not available (FOSS build for instance), MACH= and PROD= have to be
# provided when calling make.
MACH ?= $(patsubst $(PWD)/%/apps_proc,%,$(APPS_DIR))
ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x15-bin/files))
  MACH ?= mdm9x15
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-ar758x-bin/files))
  MACH ?= mdm9x28
  ifeq ($(PROD),)
    PROD = ar758x
  endif
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-bin/files))
  MACH ?= mdm9x28
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x40-ar759x-bin/files))
  MACH ?= mdm9x40
  ifeq ($(PROD),)
    PROD = ar759x
  endif
endif
# If the build is for virt, override.
ifneq (,$(findstring virt,$(MAKECMDGOALS)))
  MACH := virt
endif

ifneq ($(MACH),)
  MACH_ARGS := -m swi-$(MACH)
endif

# Try to get product name from manifest.xml
ifeq ($(PROD),)
  PROD := $(shell sed -nr '/product name/{s/.*name="(.*)".*/\1/;p}' $(shell pwd)/.repo/manifest.xml)
endif

ifneq ($(PROD),)
  PROD_ARGS := -P $(PROD)
endif

# This assumes you have used repo and you have legato synced
LEGATO_WORKDIR ?= $(shell pwd)/legato/

# Build with legato ?
ifndef LEGATO_BUILD
  ifneq (,$(wildcard $(LEGATO_WORKDIR)))
    LEGATO_BUILD := 1
  else
    $(warning "Legato: build disabled since '${LEGATO_WORKDIR}' does not exist")
    LEGATO_BUILD := 0
  endif
endif

# Build for mangOH ?
MANGOH_BUILD ?= $(shell [ -d meta-mangoh ] && echo -n 1)

# Include proprietary meta-swi-extras layer by default if existing
PROPRIETARY_BUILD ?= $(shell [ -d meta-swi-extras ] && echo -n 1 || echo -n 0)

# Use docker abstraction ?
USE_DOCKER ?= 0

# Use distributed building ?
USE_ICECC ?= 0

# Enable extended package group (mostly to aid debugging)
USE_UNSUPPORTED_DEBUG_IMG ?= 0

# Firmware path pointing to ar_yocto-cwe.tar.bz2
FIRMWARE_PATH ?= 0

# Toolchain prefix
SDK_PREFIX ?= 0

# Do we have to enable IMA for this build. For now,
# only ar758x should have IMA build enabled.
IMA_BUILD ?= 0

# Default location of the IMA configuration file. It is very difficult to
# type number of parameters on make command line every time the build is run,
# or remembering to source environment before the build. So, we make it
# easy for everyone.
IMA_CONFIG ?= $(PWD)/meta-swi/common/recipes-security/ima-support-tools/files/ima.conf

# Default BB arguments
BB_ARGS ?=

all: image_bin

clean:
	rm -rf build_*

ifeq ($(USE_ICECC),1)
  ICECC_ARGS = -h
endif

# Use extended image.
ifeq ($(USE_UNSUPPORTED_DEBUG_IMG),1)
  EXT_SWI_IMG_ARGS = -E
endif

ifdef FW_VERSION
  FW_VERSION_ARG := -v $(FW_VERSION)
endif

ifeq ($(LEGATO_BUILD),1)
  ifdef LEGATO_WORKDIR
    LEGATO_ARGS := -g -a "LEGATO_WORKDIR=${LEGATO_WORKDIR}"
  endif
endif

ifeq ($(MANGOH_BUILD),1)
  MANGOH_WIFI_REPO := "$(PWD)/mangOH/WiFi"
  MANGOH_ARGS := -M \
                 -a "MANGOH_WIFI_REPO=${MANGOH_WIFI_REPO}"
endif

ifeq ($(IMA_BUILD),1)
 ifeq (,$(filter $(MACH),virt)$(filter $(MACH),mdm9x28))
    $(error "IMA is not supported for [${MACH}][${PROD}]")
  else
    IMA_ARGS := -i ${IMA_CONFIG}
  endif
endif

ifneq (,$(wildcard $(PWD)/legato/3rdParty/ima-support-tools/))
  IMA_ARGS += -a "IMA_SUPPORT_TOOLS_REPO=git://$(PWD)/legato/3rdParty/ima-support-tools/.git;protocol=file;rev=HEAD"
endif

ifneq ($(FIRMWARE_PATH),0)
  FIRMWARE_PATH_ARGS := -F $(FIRMWARE_PATH)
endif

ifneq ($(SDK_PREFIX),0)
  SDK_PREFIX_ARGS := -a "SDKPATH_PREFIX=${SDK_PREFIX}"
endif

ifdef TARGET_HOSTNAME
  HOSTNAME_ARGS := -a "hostname_pn-base-files=${TARGET_HOSTNAME}"
endif

# Determine path for LK repository
# On mdm9x15, lk is built using CAF revision + patches
ifneq (,$(wildcard $(PWD)/lk/))
  LK_REPO := "$(PWD)/lk"
  # Append LK_REPO argument for 9x28 and 9x40 targets
  ifneq (, $(filter $(MACH), mdm9x28 mdm9x40))
    LK_ARGS := -a "LK_REPO=$(LK_REPO)"
  endif
else
  # Enforce existence of LK for 9x28 and 9x40; optional for others
  ifneq (, $(filter $(MACH), mdm9x28 mdm9x40))
    $(error Missing LK directory $(PWD)/lk)
  endif
endif

ifeq ($(RECOVERY_BUILD),1)
  RCY_ARGS = -e
endif

ifdef BB_FLAGS
  BB_ARGS := -B "${BB_FLAGS}"
endif

# Replaces this Makefile by a symlink to repo.mk
$(shell if ! test -h Makefile; then rm -f Makefile && ln -s meta-swi/repo.mk Makefile; fi)

BUILD_SCRIPT := "meta-swi/build.sh"

# Provide a docker abstraction for Yocto building, allowing the host seen
# by the Yocto environment to be the ideal Linux distribution
ifeq ($(USE_DOCKER),1)
  UID := $(shell id -u)
  HOSTNAME := $(shell hostname)
  DOCKER_BIN ?= docker
  DOCKER_IMG ?= "quay.io/swi-infra/yocto-dev"
  DOCKER_RUN := ${DOCKER_BIN} run \
                    --rm \
                    --user=${UID} \
                    --tty --interactive \
                    --hostname=${HOSTNAME} \
                    --volume ${PWD}:${PWD} \
                    --volume /etc/passwd:/etc/passwd \
                    --volume /etc/group:/etc/group \
                    --workdir ${PWD}
  BUILD_SCRIPT := ${DOCKER_RUN} ${DOCKER_IMG} ${BUILD_SCRIPT}
endif

COMMON_ARGS := ${BUILD_SCRIPT} \
				-p poky/ \
				-o meta-openembedded/ \
				-l meta-swi \
				-x "kernel" \
				-j $(NUM_THREADS) \
				-t $(NUM_THREADS) \
				${ICECC_ARGS} \
				${LEGATO_ARGS} \
				${FIRMWARE_PATH_ARGS} \
				${SDK_PREFIX_ARGS} \
				${HOSTNAME_ARGS} \
				${IMA_ARGS} \
				${BB_ARGS} \
				${EXT_SWI_IMG_ARGS}

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

  MACH_ARGS += -a KBRANCH_DEFAULT_MDM9X15=${KBRANCH_mdm9x15} \
               -a KMETA_DEFAULT_MDM9X15=${KMETA_mdm9x15}

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
		cd kernel && git branch master gerrit/master ; \
	fi

endif

.PHONY: prepare
prepare: $(PREPARE_TASKS)

COMMON_MACH := \
				$(COMMON_ARGS) \
				$(MANGOH_ARGS) \
				$(LK_ARGS) \
				$(MACH_ARGS) \
				${PROD_ARGS} \
				$(RCY_ARGS)

COMMON_BIN := \
				$(COMMON_MACH) \
				-b build_bin

ifeq ($(PROPRIETARY_BUILD),1)
  COMMON_BIN += -q
endif

QEMU_ARGS ?=
ifeq ($(QEMU),1)
  QEMU_ARGS := -Q
endif

COMMON_SRC := \
				$(COMMON_MACH) \
				${QEMU_ARGS} \
				-b build_src

ifeq ($(PROPRIETARY_BUILD),1)
  COMMON_SRC += -w $(APPS_DIR) $(FW_VERSION_ARG) -s
endif

## images

image_bin: prepare
	$(COMMON_BIN)

image_src: prepare
	$(COMMON_SRC)

image: image_$(DEFAULT_MDM_BUILD)

## toolchains

toolchain_bin: prepare
	$(COMMON_BIN) -k

toolchain_src: prepare
	$(COMMON_SRC) -k

toolchain: toolchain_$(DEFAULT_MDM_BUILD)

## dev shell

dev_bin: prepare
	$(COMMON_BIN) -c

dev_src: prepare
	$(COMMON_SRC) -c

dev: dev_$(DEFAULT_MDM_BUILD)

## binary layer generation

BIN_LAYER_ARGS := -m $(MACH)
ifneq ($(PROD),)
  BIN_LAYER_ARGS += -P $(PROD)
endif

binary_layer:
	$(PWD)/meta-swi-extras/create_bin_layer.sh \
		-b $(PWD)/build_src/ \
		-o $(PWD)/build_src/binary_layer/ \
		$(BIN_LAYER_ARGS)

# Machine: swi-virt

COMMON_VIRT_ARM := \
				$(COMMON_ARGS) \
				-m swi-virt-arm \
				-b build_virt-arm

COMMON_VIRT_X86 := \
				$(COMMON_ARGS) \
				-m swi-virt-x86 \
				-b build_virt-x86

## images

image_virt_arm:
	$(COMMON_VIRT_ARM)

image_virt_x86:
	$(COMMON_VIRT_X86)

image_virt: image_virt_arm

## toolchains

toolchain_virt_arm:
	$(COMMON_VIRT_ARM) -k

toolchain_virt_x86:
	$(COMMON_VIRT_X86) -k

toolchain_virt: toolchain_virt_arm

## dev shell

dev_virt_arm:
	$(COMMON_VIRT_ARM) -c

dev_virt_x86:
	$(COMMON_VIRT_X86) -c

dev_virt: dev_virt_arm

