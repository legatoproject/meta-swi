# DM, FIXME: tzdata recipe was "borrowed" from poky 2.5. However, d.getVar methods in Y2.2 and Y2.5
# are different. This change is here to allow proper compilation of tzdata in Y2.2 environment.
CONFFILES_${PN} += "${@ "${sysconfdir}/timezone" if bb.utils.to_boolean(d.getVar('INSTALL_TIMEZONE_FILE', True)) else "" }"

# We need to add/change a few things.
FILES_${PN} += "/usr/share/zoneinfo/localtime"

FILES_${PN} += "${datadir}/zoneinfo/Pacific/Marquesas   \
                ${datadir}/zoneinfo/America/St_Johns    \
                ${datadir}/zoneinfo/Asia/Tehran         \
                ${datadir}/zoneinfo/Asia/Kabul          \
                ${datadir}/zoneinfo/Asia/Kolkata        \
                ${datadir}/zoneinfo/Asia/Kathmandu      \
                ${datadir}/zoneinfo/Asia/Rangoon        \
                ${datadir}/zoneinfo/Australia/Eucla     \
                ${datadir}/zoneinfo/Australia/Lord_Howe \
                ${datadir}/zoneinfo/Pacific/Norfolk     \
                ${datadir}/zoneinfo/Pacific/Chatham"

do_install_append () {

    # We do have RO file systems, and on these, we cannot change
    # timezone links. So, make sure that default timezone file name
    # is neutral, so we could bind mount timezones onto it and
    # leave original localtime softlink alone.
    cp -f ${D}${datadir}/zoneinfo/${DEFAULT_TIMEZONE} ${D}${datadir}/zoneinfo/localtime
    rm -f ${D}${sysconfdir}/localtime
    ln -s ${datadir}/zoneinfo/localtime ${D}${sysconfdir}/localtime
}
