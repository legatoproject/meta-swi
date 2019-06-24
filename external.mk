# Set number of threads
NUM_THREADS ?= 9

DEFAULT_MDM_BUILD := bin

# Yocto versions
YOCTO_MAJOR = $(shell git --git-dir=poky/.git describe --tags --match 'yocto-*' | sed 's/yocto-\([0-9]*\)\.\([0-9]*\).*/\1/g')
YOCTO_MINOR = $(shell git --git-dir=poky/.git describe --tags --match 'yocto-*' | sed 's/yocto-\([0-9]*\)\.\([0-9]*\).*/\2/g')

POKY_VERSION ?= bda51ee7821de9120f6f536fcabe592f2a0c8a37
META_OE_VERSION ?= 8e6f6e49c99a12a0382e48451f37adac0181362f

# Machine architecture
# Guess the architecture and product based on the availability of proprietary binaries.
# If binaries are not available (FOSS build for instance), MACH= and PROD= have to be
# provided when calling make.
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

ifneq ($(PROD),)
  PROD_ARGS := -P $(PROD)
endif

# This assumes you have a legato dir at the root level of
# other Yocto sources
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

ifeq ($(SHARED_SSTATE),1)
  SHARED_SSTATE_ARGS = -S
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
  IMA_ARGS += -a "IMA_SUPPORT_TOOLS_REPO=file://$(PWD)/legato/3rdParty/ima-support-tools/"
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

# Replaces this Makefile by a symlink to external.mk
$(shell if ! test -h Makefile; then rm -f Makefile && ln -s meta-swi/external.mk Makefile; fi)

BUILD_SCRIPT := "meta-swi/build.sh"

# Provide a docker abstraction for Yocto building, allowing the host seen
# by the Yocto environment to be the ideal Linux distribution
ifeq ($(USE_DOCKER),1)
  UID := $(shell id -u)
  GID := $(shell id -g)
  HOSTNAME := $(shell hostname)
  DOCKER_BIN ?= docker
  DOCKER_IMG ?= "quay.io/swi-infra/yocto-dev:yocto-${YOCTO_MAJOR}.${YOCTO_MINOR}"
  DOCKER_RUN := ${DOCKER_BIN} run \
                    --rm \
                    --user=${UID}:${GID} \
                    --tty --interactive \
                    --hostname=${HOSTNAME} \
                    --volume ${PWD}:${PWD} \
                    --volume /etc/passwd:/etc/passwd:ro \
                    --volume /etc/group:/etc/group:ro \
                    --workdir ${PWD} \
                    --env USE_ICECC \
                    --env SHARED_SSTATE \
                    --env USE_UNSUPPORTED_DEBUG_IMG \
                    --env FW_VERSION \
                    --env LEGATO_BUILD \
                    --env MANGOH_BUILD \
                    --env IMA_BUILD \
                    --env IMA_CONFIG \
                    --env SDK_PREFIX \
                    --env FIRMWARE_PATH \
                    --env TARGET_HOSTNAME \
                    --env RECOVERY_BUILD
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
				${EXT_SWI_IMG_ARGS} \
				${SHARED_SSTATE_ARGS}

# Machine: swi-mdm9x15

ifeq ($(MACH),mdm9x15)
  KBRANCH_mdm9x15 := $(shell git --git-dir=kernel/.git branch | grep -oe 'standard/.*')
  KMETA_mdm9x15 := $(shell git --git-dir=kernel/.git branch | grep -oe 'meta-.*')

  MACH_ARGS += -a KBRANCH_DEFAULT_MDM9X15=${KBRANCH_mdm9x15} \
               -a KMETA_DEFAULT_MDM9X15=${KMETA_mdm9x15}
endif

## extras needed for building

poky:
	git clone git://git.yoctoproject.org/poky
	cd poky && git checkout ${POKY_VERSION}

meta-openembedded:
	git clone git://git.openembedded.org/meta-openembedded
	cd meta-openembedded && git checkout ${META_OE_VERSION}

.PHONY: prepare
prepare: poky meta-openembedded

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

## images

image_bin: prepare
	$(COMMON_BIN)

image: image_$(DEFAULT_MDM_BUILD)

## toolchains

toolchain_bin: prepare
	$(COMMON_BIN) -k

toolchain: toolchain_$(DEFAULT_MDM_BUILD)

## dev shell

dev_bin: prepare
	$(COMMON_BIN) -c

dev: dev_$(DEFAULT_MDM_BUILD)

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

