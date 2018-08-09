# Fix everything that's wrong with the original recipe
VERSNUM = "1.0.4"
# Do not use tag in SRCREV, it is not going to work in "no network" mode.
SRCREV = "e0e8bcda58e89a5c5282772b175c664839d926df"
PV = "${VERSNUM}+git${SRCPV}"
DEPENDS_BZIP2_class-nativesdk = "bzip2"
BBCLASSEXTEND += "nativesdk"
