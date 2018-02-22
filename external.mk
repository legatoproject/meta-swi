# Set number of threads
NUM_THREADS ?= 9

# Yocto versions
POKY_VERSION ?= bda51ee7821de9120f6f536fcabe592f2a0c8a37
META_OE_VERSION ?= 8e6f6e49c99a12a0382e48451f37adac0181362f

# Machine architecture
ifeq ($(MACH),)
  ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x15-bin/files))
    MACH := mdm9x15
  else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-ar758x-bin/files))
    MACH := mdm9x28
    PROD ?= ar758x
  else ifneq (,$(wildcard $(PWD)/meta-swi-extras/meta-swi-mdm9x28-bin/files))
    MACH := mdm9x28
  endif
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

# Include prorpietary meta-swi-extras layer by default if existing
PROPRIETARY_BUILD ?= $(shell [ -d meta-swi-extras ] && echo -n 1 || echo -n 0)

# Use docker abstraction ?
USE_DOCKER ?= 0

# Use distributed building ?
USE_ICECC ?= 0

# Firmware path pointing to ar_yocto-cwe.tar.bz2
FIRMWARE_PATH ?= 0

# Toolchain prefix
SDK_PREFIX ?= 0

all: image_bin

clean:
	rm -rf build_*

ifeq ($(USE_ICECC),1)
  ICECC_ARGS = -h
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

ifneq ($(FIRMWARE_PATH),0)
  FIRMWARE_PATH_ARGS := -F $(FIRMWARE_PATH)
endif

ifneq ($(SDK_PREFIX),0)
  SDK_PREFIX_ARGS := -a "SDKPATH_PREFIX=${SDK_PREFIX}"
endif


# Determine path for LK repository
# On mdm9x15, lk is built using CAF revision + patches
ifneq (,$(wildcard $(PWD)/lk/))
  LK_REPO ?= "$(PWD)/lk"
endif
ifneq (,$(LK_REPO))
  ifneq (mdm9x15,$(MACH))
    LK_ARGS := -a "LK_REPO=$(LK_REPO)"
  endif
endif

# Replaces this Makefile by a symlink to external.mk
$(shell if ! test -h Makefile; then rm -f Makefile && ln -s meta-swi/external.mk Makefile; fi)

BUILD_SCRIPT := "meta-swi/build.sh"

# Provide a docker abstraction for Yocto building, allowing the host seen
# by the Yocto environment to be the ideal Linux distribution
ifeq ($(USE_DOCKER),1)
  UID := $(shell id -u)
  HOSTNAME := $(shell hostname)
  DOCKER_BIN ?= docker
  DOCKER_IMG ?= "corfr/yocto-dev"
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
				-x "kernel/.git" \
				-j $(NUM_THREADS) \
				-t $(NUM_THREADS) \
				${ICECC_ARGS} \
				${LEGATO_ARGS} \
				${FIRMWARE_PATH_ARGS} \
				${SDK_PREFIX_ARGS}

# Machine: swi-mdm9x15

ifeq ($(MACH),mdm9x15)
  MACH_ARGS += -a KBRANCH_DEFAULT_MDM9X15=${KBRANCH_mdm9x15} \
               -a KMETA_DEFAULT_MDM9X15=${KMETA_mdm9x15}
endif

COMMON_MACH := \
				$(COMMON_ARGS) \
				$(MANGOH_ARGS) \
				$(LK_ARGS) \
				$(MACH_ARGS) \
				${PROD_ARGS}

COMMON_BIN := \
				$(COMMON_MACH) \
				-b build_bin

ifeq ($(PROPRIETARY_BUILD),1)
  COMMON_BIN += -q
endif

## extras needed for building

poky:
	git clone git://git.yoctoproject.org/poky
	cd poky && git checkout ${POKY_VERSION}

meta-openembedded:
	git clone git://git.openembedded.org/meta-openembedded
	cd meta-openembedded && git checkout ${META_OE_VERSION}

## images

image_bin: poky meta-openembedded
	$(COMMON_BIN)

image: image_bin

## toolchains

toolchain_bin: poky meta-openembedded
	$(COMMON_BIN) -k

toolchain: toolchain_bin

## dev shell

dev: poky meta-openembedded
	$(COMMON_BIN) -c

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
	$(COMMON_VIRT_ARM) -d

image_virt_x86:
	$(COMMON_VIRT_X86) -d

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
