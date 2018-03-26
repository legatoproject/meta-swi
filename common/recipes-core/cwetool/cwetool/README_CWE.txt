yoctocwetool.sh
---------------

This tool is used to package up the linux bootloader, kernel and root file system into a single CWE
file for downloading to the modem.  Give the -h option for usage info.


makefota
--------

This tool is a temporary tool to add the FOTA header to CWE files.  This is necessary because the
modem firmware currently only supports FOTA CWE files.  Once the modem firmware has been updated to
support other types of CWE files, this tool will no longer be necessary, and it will be removed.

Usage:
    makefota FILE.cwe [package ID]

Generates the file FILE_fotapkg.cwe. Package ID is optional and should be either A911 (for AR7) or
9X15 (for WP7); defaults to A911.

