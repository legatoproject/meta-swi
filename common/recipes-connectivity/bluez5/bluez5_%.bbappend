# Third party patches
META_BOUNDARY_BASE = "git/meta-boundary"
CODEAURORA_BASE = "git/codeaurora"

# Location of Tufello support patch. 0001-hciattach-add-QCA9377-Tuffello-support.patch
# is coming from public repo, and it is misspelled (Tufello is area of Italian city of Rome).
SRC_URI += "file://0001-hciattach-add-QCA9377-Tuffello-support.patch"
SRC_URI += "file://0001-tufello-support-fixups.patch"
SRC_URI += "file://0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch"
SRC_URI += "file://0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch"

# If MODULE_HAS_MAC_ADDR is defined, MAC address stored in NV parameters will be ignored.
# For now, leave it as defined, and we will decide later on, how we are going to configure
# the system.
# I am also defining FW_CONFIG_FILE_PATH for better control outside the source code.
# However, you need to be really careful, because there are some other files which
# would need to be stored in /etc/bluetooth, and this directory would need to exist.
# Note that if you add _PLATFORM_MDM_, that firmware files must be located
# @ /lib/firmware, otherwise in /lib/firmware/qca .
EXTRA_OEMAKE += "\
  CPPFLAGS='-DMODULE_HAS_MAC_ADDR -D_PLATFORM_MDM_ -DFW_CONFIG_FILE_PATH=\"/etc/bluetooth/firmware.conf\"' \
"

# EXTRA_OEMAKE += "\
#  CPPFLAGS='-DMODULE_HAS_MAC_ADDR -DFW_CONFIG_FILE_PATH=\"/etc/bluetooth/firmware.conf\"' \
# "

# Get other repositories.
python do_fetch_prepend() {
    bb.build.exec_func('do_get_metaboundary', d)
    bb.build.exec_func('do_get_codeaurora', d)
}

# We need to do this because we need patch from this repository
# to be ready before fetch starts. The patch is on master, and
# we also need to use specific version.
do_get_metaboundary() {
    if [ ! -d ${WORKDIR}/${META_BOUNDARY_BASE}/.git ] ; then
        cd ${WORKDIR}
        git clone git://github.com/boundarydevices/meta-boundary ${META_BOUNDARY_BASE}
        cd ${META_BOUNDARY_BASE}
        git checkout master
        git reset --hard b4af8ed90414d759f0ac7a26fb91a6da808682b8
        cp ${WORKDIR}/${META_BOUNDARY_BASE}/recipes-connectivity/bluez5/bluez5/0001-hciattach-add-QCA9377-Tuffello-support.patch ${WORKDIR}
    fi
}

do_get_codeaurora() {
    if [ ! -d ${WORKDIR}/${CODEAURORA_BASE}/bluez/.git ] ; then
        cd ${WORKDIR}
        git clone git://codeaurora.org/quic/la/platform/external/bluetooth/bluez ${CODEAURORA_BASE}/bluez
        cd ${CODEAURORA_BASE}/bluez
        git checkout master
        git format-patch -1 84cc0e12983b5761c67789ef93fd6fb164c7314d
        cp 0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch ${WORKDIR}/0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch.orig
        git format-patch -1 c0ac135b68f339441700014c0ddce9b4ee8c6dca
        cp 0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch ${WORKDIR}/0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch.orig

        # Fix few patches, because they do not fully apply.
        cd ${WORKDIR}

        # 0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch
        sed \
            -e '38,+0d' \
            -e '63,+12d' \
            -e 's/@@ -1700,6 +1700,14 @@/@@ -1742,6 +1742,14 @@/' \
            -e 's/@@ -1813,5 +1821,10 @@ download:/@@ -1867,5 +1874,10 @@/' \
            -e '/vnd_userial.fd = fd\;/{G;}' \
            -e 's/if((err = rome_patch_ver_req(fd)) <0){/if ((err = rome_patch_ver_req(fd)) < 0) {/' \
            -e 's/return err/return ret/' \
            -e '40s/^     / \t/' \
            -e '49s/^     / \t/' \
            -e '50s/^     / \t/' \
            -e '51s/^         / \t\t/' \
            -e '53s/^     / \t/' \
            -e '61s/^     / \t/' \
          0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch.orig >0001-bluetooth-Vote-UART-CLK-ON-prior-to-firmware-downloa.patch

          # 0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch
          sed \
            -e '24s/^     / \t/' \
            -e '35s/^     / \t/' \
            -e '36s/^     / \t/' \
            -e '37s/^         / \t\t/' \
            -e '39s/^     / \t/' \
            -e '49s/^     / \t/' \
            -e '51,+15d' \
            -e 's/return err/return ret/' \
            -e 's/@@ -1779,13 +1779,14 @@/@@ -1742,13 +1742,14 @@/' \
            -e 's/@@ -1923,10 +1924,12 @@/@@ -1876,10 +1876,12 @@/' \
          0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch.orig >0001-Adding-MDM-specific-code-under-_PLATFORM_MDM_.patch
    fi
}

PACKAGECONFIG_append = " mesh"
PACKAGECONFIG_append = " nfc"
