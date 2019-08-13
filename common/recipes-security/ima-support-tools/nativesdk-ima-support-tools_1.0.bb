# 'require' is used instead of 'include', because 'require'
# fails if file cannot be found.
require ima-support-tools_${PV}.bb

PROVIDES += "nativesdk-ima-support-tools"

inherit nativesdk

