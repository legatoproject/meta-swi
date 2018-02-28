#
#============================================================================
# Python script to update the APP partition according to customer needs
#
# Copyright: (c) 2015 Sierra Wireless, Inc.
#            All rights reserved
#
#----------------------------------------------------------------------------
#
# Input:
#	The customer partition description file in XML
#	The binary partition file from CWE
# Output:
#	The binary partition file updated with customer scheme
# Example of file:
# <?xml version="1.0" encoding="utf-8"?>
# <partitions>
# 	<partition>
# 		<name length="16" type="string">0:APPS</name>
# 		<size_kb length="4">8000</size_kb>
# 		<pad_kb length="4">384</pad_kb>
# 	</partition>		
# 	<partition>
# 		<name length="16" type="string">0:SYSTEM</name>
# 		<size_kb length="4">50000</size_kb>
# 		<pad_kb length="4">300</pad_kb>
# 	</partition>		
# 	<partition>
# 		<name length="16" type="string">0:USERDATA</name>
# 		<size_kb length="4">28000</size_kb>
# 		<pad_kb length="4">2560</pad_kb>
# 	</partition>		
# 	<partition>
# 		<name length="16" type="string">0:USERAPP</name>
# 		<size_kb length="4">174000</size_kb>
# 		<pad_kb length="4">384</pad_kb>
# 	</partition>		
# </partitions>
#

import os
import sys
import xml.etree.ElementTree

# Write a four-bytes integer to a file as binary in little endian
def write_int( value ) :
	for i in range(4) :
		f.write( chr((value >> (8*i)) & 0xFF) )

# Only the following partitions may be updated by the script
partname=['0:APPSBL','0:APPS','0:SYSTEM','0:USERDATA','0:USERAPP']
sizekb = []
padkb = []
ipart = 0

# Script requires 3 arguments
if len(sys.argv) < 3:
	print "Usage: python partition_update.py sourcefile.xml binaryfile.bin"
	sys.exit( 1 )

# Check for both input file (read) and output file (read+write) access
if not os.access( sys.argv[1], os.R_OK ) or not os.access( sys.argv[2], os.W_OK ) :
	print "Input file or output file missing"
	sys.exit( 1 )

# Open the input file as XML
root = xml.etree.ElementTree.parse(sys.argv[1]).getroot()

if root.tag != "partitions" :
	print "Tag <partitions> expected"
	sys.exit( 1 )

for child in root:
	if child.tag != "partition" :
		print "Tag <partition> expected"
		sys.exit( 1 )
	for part in child:
		pname = ""
		if part.tag == 'name' :
			pname = "".join( part.text )
			if pname != partname[ipart] :
				print "Error in expected partition order %s" % partname[ipart]
				sys.exit( 1 )
			print "Parsing partition %s" % pname
			ipart += 1
		if part.tag == 'size_kb' :
			sizekb.append(int(part.text))
		if part.tag == 'pad_kb' :
			padkb.append( int(part.text) )

# Check if all 4 partitions have been filled properly
if ipart != 5 and len(sizekb) != 5 and len(padkb) != 5 :
	print "Missing partition..."
	sys.exit( 1 )

# Open the partition file to update
f = open( sys.argv[2], 'r+b' )

# Should be exactly on APPS partition, else file is corrupted
f.seek( 0x1d0 )
if f.read(16) != partname[0].ljust(16, '\0' ) :
	print "Output file corrupted"
	sys.exit( 2 )

# Update the partitions
f.seek( 0x1d0 )
for i in range(5) :
	print "Writing partition data for %s" % partname[i]
	f.write( partname[i].ljust(16, '\0' ) )
	write_int( int(sizekb[i]) )
	write_int( int(padkb[i]) )
	f.seek( f.tell() + 4 )

f.close
sys.exit( 0 )

