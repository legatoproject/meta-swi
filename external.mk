# Set number of threads
NUM_THREADS ?= 9

# Check for accidental recursion: user running "make" again after stepping into
# bitbake environment with make dev.

ifneq ($(BBPATH)$(BUILDDIR),)
$(error "Detected Makefile being re-invoked from within bitbake environment!")
endif

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
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-wp-bin/files))
  MACH ?= mdm9x28
  ifeq ($(PROD),)
    PROD = wp
  endif
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-bin/files))
  MACH ?= mdm9x28
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x40-ar759x-bin/files))
  MACH ?= mdm9x40
  ifeq ($(PROD),)
    PROD = ar759x
  endif
else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-fx30-bin/files))
  MACH ?= mdm9x28
  ifeq ($(PROD),)
    PROD = fx30
  endif
endif
# If the build is for virt, override.
ifneq (,$(findstring virt,$(MAKECMDGOALS)))
  MACH := virt
endif

ifneq ($(MACH),)
  MACH_ARGS := --machine-type=swi-$(MACH)
endif

ifneq ($(PROD),)
  PROD_ARGS := --product=$(PROD)
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

# Build and generate additional debug image which includes extended packages
DEBUG_IMG_BUILD ?= 0

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
  ICECC_ARGS = --enable-icecc
endif

ifeq ($(SHARED_SSTATE),1)
  SHARED_SSTATE_ARGS = --enable-shared-sstate
endif

# Use extended image.
ifeq ($(USE_UNSUPPORTED_DEBUG_IMG),1)
  EXT_SWI_IMG_ARGS = --enable-extended-image
endif

# Build extended packages and generate debug image.
ifeq ($(DEBUG_IMG_BUILD),1)
  ifeq ($(USE_UNSUPPORTED_DEBUG_IMG),0)
    DEBUG_IMG_ARGS = --enable-debug-image
  endif
endif

ifdef FW_VERSION
  FW_VERSION_ARG := --qct-version=$(FW_VERSION)
endif

ifeq ($(LEGATO_BUILD),1)
  ifdef LEGATO_WORKDIR
    LEGATO_ARGS := --enable-legato --recipe-args="LEGATO_WORKDIR=${LEGATO_WORKDIR}"
  endif
endif

ifeq ($(MANGOH_BUILD),1)
  MANGOH_WIFI_REPO := "$(PWD)/mangOH/WiFi"
  MANGOH_ARGS := --enable-mangoh \
                 --recipe-args="MANGOH_WIFI_REPO=${MANGOH_WIFI_REPO}"
endif

ifeq ($(IMA_BUILD),1)
 ifeq (,$(filter $(MACH),virt)$(filter $(MACH),mdm9x28))
    $(error "IMA is not supported for [${MACH}][${PROD}]")
  else
    IMA_ARGS := --ima-config-file=${IMA_CONFIG}
  endif
endif

ifneq (,$(wildcard $(PWD)/legato/3rdParty/ima-support-tools/))
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_DIR=$(PWD)/legato/3rdParty/"
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_REPO=file://ima-support-tools"
  IMA_ARGS += --recipe-args="IMA_SUPPORT_TOOLS_NAME=ima-support-tools"
endif

ifneq ($(FIRMWARE_PATH),0)
  FIRMWARE_PATH_ARGS := --ar-yocto-path=$(FIRMWARE_PATH)
endif

ifneq ($(SDK_PREFIX),0)
  SDK_PREFIX_ARGS := --recipe-args="SDKPATH_PREFIX=${SDK_PREFIX}"
endif

ifdef TARGET_HOSTNAME
  HOSTNAME_ARGS := --recipe-args="hostname_pn-base-files=${TARGET_HOSTNAME}"
endif

# Determine location of LK.
#
# This potentially establishes three bitbake variables, which are all used in
# the base lk recipe.
#
# LK_REPO_DIR:  parent directory in which lk is located, added by
#               the lk base recipe to FILESPATH. If it is not defined,
#               the base recipe safely defaults it to ${THISDIR}.
# LK_REPO:      The fetch URI designating lk. The base recipe interpolates
#               this into the SRC_URI variable. It provides no default;
#               systems that don't have a lk directory in the tree must
#               set this variable in their lk bbappend recipe to point
#               to some external lk repository.
# LK_REPO_NAME: The subdirectory name where lk is fetched inside ${WORKDIR}.
#               If it is not defined, it defaults to "git", which works
#               for overriding recipes like mdm9x15 that specify an
#               external git URL. The base recipe uses this to define
#               the ${S} directory as "${WORKDIR}/${LK_REPO_NAME}".
#
ifneq (,$(wildcard $(PWD)/lk/))
  # If we have an in-tree lk, then set up all three variables accordingly.
  LK_ARGS := --recipe-args=LK_REPO_DIR="$(PWD)"\ LK_REPO_NAME="lk"\ LK_REPO="file://lk"
else
  # Enforce existence of LK for 9x28 and 9x40; optional for others
  ifneq (, $(filter $(MACH), mdm9x28 mdm9x40))
    $(error Missing LK directory $(PWD)/lk)
  endif
  # If we don't have an lk directory, LK_REPO_NAME and LK_REPO_DIR
  # default as describe above, and a lk bbappend is expected to supply LK_REPO.
endif

ifeq ($(RECOVERY_BUILD),1)
  RCY_ARGS = --enable-recovery-image
endif

ifdef BB_FLAGS
  BB_ARGS := --bitbake-flags="${BB_FLAGS}"
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
  INTERACTIVE := $(shell [ -t 0 ] && echo 1)
  ifdef INTERACTIVE
    DOCKER_TTY ?= --tty --interactive
  else
    DOCKER_TTY =
  endif
  DOCKER_RUN := ${DOCKER_BIN} run \
                    --rm \
                    --user=${UID}:${GID} \
                    ${DOCKER_TTY} \
                    --init \
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
				--poky-dir=poky/ \
				--meta-oe-dir=meta-openembedded/ \
				--meta-swi-dir=meta-swi \
				--linux-repo-dir="kernel" \
				--make-threads=$(NUM_THREADS) \
				--bitbake-tasks=$(NUM_THREADS) \
				${ICECC_ARGS} \
				${LEGATO_ARGS} \
				${FIRMWARE_PATH_ARGS} \
				${SDK_PREFIX_ARGS} \
				${HOSTNAME_ARGS} \
				${IMA_ARGS} \
				${BB_ARGS} \
				${EXT_SWI_IMG_ARGS} \
				${SHARED_SSTATE_ARGS} \
				${DEBUG_IMG_ARGS}

# Machine: swi-mdm9x15

ifeq ($(MACH),mdm9x15)
  KBRANCH_mdm9x15 := $(shell git --git-dir=kernel/.git branch | grep -oe 'standard/.*')
  KMETA_mdm9x15 := $(shell git --git-dir=kernel/.git branch | grep -oe 'meta-.*')

  MACH_ARGS += --recipe-args=KBRANCH_DEFAULT_MDM9X15=${KBRANCH_mdm9x15} \
               --recipe-args=KMETA_DEFAULT_MDM9X15=${KMETA_mdm9x15}
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
				--build-dir=build_bin

ifeq ($(PROPRIETARY_BUILD),1)
  COMMON_BIN += --enable-prop-bin
endif

## images

image_bin: prepare
	$(COMMON_BIN)

image: image_$(DEFAULT_MDM_BUILD)

## toolchains

toolchain_bin: prepare
	$(COMMON_BIN) --build-toolchain

toolchain: toolchain_$(DEFAULT_MDM_BUILD)

## dev shell

dev_bin: prepare
	$(COMMON_BIN) --cmdline-mode

dev: dev_$(DEFAULT_MDM_BUILD)

# Machine: swi-virt

COMMON_VIRT_ARM := \
				$(COMMON_ARGS) \
				--machine-type=swi-virt-arm \
				--build-dir=build_virt-arm

COMMON_VIRT_X86 := \
				$(COMMON_ARGS) \
				--machine-type=swi-virt-x86 \
				--build-dir=build_virt-x86

## images

image_virt_arm:
	$(COMMON_VIRT_ARM)

image_virt_x86:
	$(COMMON_VIRT_X86)

image_virt: image_virt_arm

## toolchains

toolchain_virt_arm:
	$(COMMON_VIRT_ARM) --build-toolchain

toolchain_virt_x86:
	$(COMMON_VIRT_X86) --build-toolchain

toolchain_virt: toolchain_virt_arm

## dev shell

dev_virt_arm:
	$(COMMON_VIRT_ARM) --cmdline-mode

dev_virt_x86:
	$(COMMON_VIRT_X86) --cmdline-mode

dev_virt: dev_virt_arm

