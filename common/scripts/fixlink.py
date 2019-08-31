#!/usr/bin/env python3

#
# Script to correct and relativize absolute symlinks in a directory tree.
#
# Recursively scans the directory tree rooted at the specified root, which
# is considered to be a system root.  Each absolute symlink that is encountered
# is assumed to be in the context of that root rather than the host system's
# root. It is repaired accordingly, and then relativized.
#
# For instance: if /path/to/root/usr/bin/foo is a symlink to
# /usr/local/bin/bar, then firstly, this link target assumed to be incorrectly
# sysrooted and is relativized to the root / to form usr/local/bin/bar,
# and then joined to the root path to form /path/to/root/usr/local/bin/bar.
# This sysrooted path is then again relativized to ../local/bin/bar
# and that is finally installed in place of the original symlink. This
# relative link then remains correct even if that root is moved around.
#
# If a second argument is given, it specifies an "extra root", which
# should be an absolute path. Symlink targets which point to paths
# under this root are first relativized to that root, rather than to /.
# If this argument is /abc/xyz and if /path/to/root/usr/bin/foo is a
# symlink to /abc/xyz/usr/local/bin/bar, then this match is detected.
# The target is relativized against /abc/xyz to produce # usr/local/bin/bar,
# and then catenated with the root to make /path/to/root/usr/local/bin/bar,
# and finally relativized to ../local/bin/bar.
#

import os, sys

root = sys.argv[1]

exroot = sys.argv[2] if (len(sys.argv) >= 3) else None

for dir, subdirs, files in os.walk(root):
  for fname in files:
    path = os.path.join(dir, fname)
    if (os.path.islink(path)):
      target = os.readlink(path)
      if os.path.isabs(target):
        if exroot and target.startswith(exroot):
          rootrel = os.path.relpath(target, exroot)
        else:
          rootrel = os.path.relpath(target, "/")
        hostabs = os.path.join(root, rootrel)
        linkrel = os.path.relpath(hostabs, dir)
        os.remove(path)
        os.symlink(linkrel, path)
