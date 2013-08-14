DESCRIPTION = "kernel tests"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://Makefile;beginline=2;endline=8;md5=376fee2441c6c484d1ec7d607664c6db"

inherit module

PR = "r0"
PV = "0.1"

SRC_URI = "file://Makefile \
	   file://gpio-test.c \
	   file://spi-dev-module.c"

S = "${WORKDIR}"

