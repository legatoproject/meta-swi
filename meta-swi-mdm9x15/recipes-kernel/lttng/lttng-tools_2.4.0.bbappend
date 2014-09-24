#fixing lttng compilation issue
#http://bugs.lttng.org/issues/640

export CFLAGS = "-DSIERRA -Wall -DSIERRA -O0 -pipe -g -feliminate-unused-debug-types -g -fno-strict-aliasing"

