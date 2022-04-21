# Look for files in the layer first
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

PACKAGECONFIG[no-tls1] = "no-tls1 no-tls1-method"
PACKAGECONFIG[no-tls1_1] = "no-tls1_1 no-tls1_1-method"

# Note: Remove the following definition of DEPRECATED_CRYPTO_FLAGS and the append to EXTRA_OECONF,
# once the main recipe is upgraded to a version containing DEPRECATED_CRYPTO_FLAGS in do_configure.

# Disable deprecated crypto algorithms
# Retained for compatibilty
# des (curl)
# dh (python-ssl)
# dsa (rpm)
# md4 (cyrus-sasl freeradius hostapd)
# bf (wvstreams postgresql x11vnc crda znc cfengine)
# rc4 (freerdp librtorrent ettercap xrdp transmission pam-ssh-agent-auth php)
# rc2 (mailx)
# psk (qt5)
# srp (libest)
# scrypt (python)
# whirlpool (qca)
DEPRECATED_CRYPTO_FLAGS = "no-ssl no-idea no-rc5 no-md2 no-camellia no-mdc2 no-seed no-siphash no-sm2 no-sm3 no-sm4"

EXTRA_OECONF += "--api=1.1.1 ${DEPRECATED_CRYPTO_FLAGS}"
EXTRA_OECONF:class-native += " --api=1.1.1"
EXTRA_OECONF:class-nativesdk += " --api=1.1.1"

# Disable algorithms and protocols not in Sierra Wireless approved list:
# TLS1.0, TLS1.1 and DTSL1.
PACKAGECONFIG += "no-tls1 no-tls1_1"
SWI_DISALLOWED_CRYPTO_FLAGS = "no-dtls1 no-dtls1-method"
EXTRA_OECONF += "${SWI_DISALLOWED_CRYPTO_FLAGS}"

SRC_URI += "file://0001-conf-Allow-only-approved-Cipher-suites.patch"
