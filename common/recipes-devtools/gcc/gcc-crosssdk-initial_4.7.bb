require gcc-cross-initial_${PV}.bb
require gcc-crosssdk-initial.inc
EXTRA_OECONF += " --with-native-system-header-dir=${SYSTEMHEADERS} "

