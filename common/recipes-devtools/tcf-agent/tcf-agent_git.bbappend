INITSCRIPT_PARAMS = "start 99 S . stop 20 S ."

# Prevent dependency on bash
RDEPENDS_${PN} = ""
CFLAGS += " -DTERMINALS_NO_LOGIN=0"

