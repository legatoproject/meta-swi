# Look for files in the layer first
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

VER_1_0_2p_PATCHES := "file://CVE-2018-0734.patch \
                       file://CVE-2019-1559_1.patch \
                       file://CVE-2019-1559_2.patch"

SRC_URI += "${@oe.utils.conditional('PV', '1.0.2p', '${VER_1_0_2p_PATCHES}', '', d)}"

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
# whirlpool (qca)
DEPRECATED_CRYPTO_FLAGS = "no-ssl no-idea no-rc5 no-md2 no-camellia no-mdc2 no-scrypt no-seed no-siphash no-sm2 no-sm3 no-sm4"

EXTRA_OECONF += "${DEPRECATED_CRYPTO_FLAGS}"

# Disable algorithms and protocols not in Sierra Wireless approved list:
# TLS1.0, TLS1.1 and DTSL1.
PACKAGECONFIG += "no-tls1 no-tls1_1"
SWI_DISALLOWED_CRYPTO_FLAGS = "no-dtls1 no-dtls1-method"
EXTRA_OECONF += "${SWI_DISALLOWED_CRYPTO_FLAGS}"

SRC_URI += "file://0001-conf-Allow-only-approved-Cipher-suites.patch"
