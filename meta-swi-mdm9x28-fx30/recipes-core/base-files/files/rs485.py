#!/usr/bin/env python3

import sys

fn = sys.argv[1]
if len(sys.argv) > 2:
    value = sys.argv[2]
else:
    value = None

ttyFile=open('/dev/ttyHSL0')

if value is None:
    sysfsFile = open(fn, 'r')
    print(sysfsFile.read().strip())
else:
    sysfsFile = open(fn, 'w')
    sysfsFile.write(value)

