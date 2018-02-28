#
# Copyright (C) Sierra Wireless Inc. All rights reserved.
#

all: fotapkghdrcat cwezip hdrcnv splitboot

clean:
	rm cwezip fotapkghdrcat hdrcnv splitboot

cwezip: cwezip.cpp
	$(CXX) -o $@ ${CPPFLAGS} ${LDFLAGS} $< -lz

fotapkghdrcat: fotapkghdrcat.cpp
	$(CXX) -o $@ ${CPPFLAGS} ${LDFLAGS} $<

hdrcnv: hdrcnv.cpp
	$(CXX) -o $@ ${CPPFLAGS} ${LDFLAGS} $<

splitboot: splitboot.c
	$(CC) -o $@ ${CFLAGS} ${LDFLAGS} $<
