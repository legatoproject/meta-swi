# 'require' is used instead of 'include', because 'require'
# fails if file cannot be found.
require ima-support-tools_${PV}.bb

SUMMARY = "IMA support tools"
DESCRIPTION = "Tools for IMA signage, key generation, etc."
DEPENDS = ""
PROVIDES += "nativesdk-ima-support-tools"

inherit nativesdk

