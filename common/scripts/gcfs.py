#!/usr/bin/env python3

#
# Script to "garbage collect" the initramfs file system rooted at the current
# working directory. The current directory "." is traversed, starting at
# the ./init script producing a list of path names that can be deleted.
#

import os
import re
import stat

#
# Regex to match a "name".
#
# A name is defined as one or more letters, digits, dashes, colons, periods,
# commas and underscores. The idea is that executable files and scripts in
# initramfs are all names.
#
name_pat = '[\w\-:.,]+'
name_regex = re.compile(name_pat)

#
# File info structure: holds information about a file or symlink.:
#
class file_info:
  def __init__ (self, path, name, strings):
    self.path = path            # pathname to file
    self.name = name            # basename of file
    self.strings = strings      # set of strings contained in file or symlink

#
# Garbage collection context: passed down in recursive GC walk.
#
class gc_context:
  def __init__ (self, pd, nd):
    self.path_dict = pd         # path -> file_info (master dict)
    self.name_dict = nd         # name -> [ file_info ...] (supplementary index)
    self.reachable = set()      # set of file_info objects that are reachable
    self.garbage = None         # set of file_info objects that are unreachable

#
# Read the file as 8 bit characters, extracting all strings,
# returning them as a set.
#
def get_strings(file, prune):
  stream = open(file, mode='r', encoding='latin-1')
  data = stream.read()
  strs = name_regex.findall(data)
  return set(strs).intersection(prune)

#
# Collect a set of all basenames contained in the filesystem
#
def get_name_set():
  out = set()
  for dirname, subdirs, files in os.walk('.'):
    out = out.union(set(files))
  return out

#
# Construct the master path dictionary of the filesystem.
# Returns a "path" -> file_info dict.
#
def path_dict():
  out = {}
  names = get_name_set()
  libnames = set([n for n in names if n.startswith('lib')])
  for dirname, subdirs, files in os.walk('.'):
    for file in files:
      path = dirname + '/' + file
      mode = os.lstat(path).st_mode
      if file == "ld.so.cache":
        continue
      elif file == "busybox" or file == "busybox.nosuid":
        out[path] = file_info(path, file, get_strings(path, libnames))
      elif (stat.S_ISREG(mode)):
        out[path] = file_info(path, file, get_strings(path, names))
      elif (stat.S_ISLNK(mode)):
        out[path] = file_info(path, file, os.readlink(path).split('/'))
  return out

#
# Augment the name_dict with additional mappings generated
# by breaking down shared library names.
# For instance, if file_info item's name is "libfoo.so.1", or "libfoo.so", we
# want to map the name "libfoo" to that item in name_dict.
# This is because an executable which uses "libfoo" might just contain
# the string "libfoo", but there is no such file.
#
def aug_shared_libs(path_dict, name_dict):
  for path, fi in path_dict.items():
    if (fi.name.endswith('.so')):
      name_dict.setdefault(fi.name[0:-3], []).append(fi)
    else:
      pos = fi.name.find('.so.')
      if pos != -1:
        name_dict.setdefault(fi.name[0:pos], []).append(fi)

#
# Construct an auxiliary dictionary which maps the names of the items in
# path_dict to lists of items which share that name. This allows our garbage
# collector to navigate a name reference to the possible list of files which it
# might be a reference to.
#
def name_dict(path_dict):
  out = {}
  for path, fi in path_dict.items():
    out.setdefault(fi.name, []).append(fi)
  return out

#
# Traverse the name reachability graph, adding visited nodes to gc.reachable.
# Whatever is left is unreachable.
#
def visit(gc, fi):
  gc.reachable.add(fi)
  for other in fi.strings:
    if other in gc.name_dict:
      fis = gc.name_dict[other]
      for fi in fis:
        if fi not in gc.reachable:
          visit(gc, fi)

#
# Entry point into garbage collector
#
def garbage_collect():
  pd = path_dict()
  nd = name_dict(pd)
  aug_shared_libs(pd, nd)
  gc = gc_context(pd, nd)
  visit(gc, gc.path_dict['./init'])   # calculate what is reachable from init script
  gc.garbage = set(gc.path_dict.values()).difference(gc.reachable)
  return gc

#
# Run garbage collector
#
gc = garbage_collect()

#
# Generate report of unreachable items. Let's be careful and just report
# the apparently unreachable executables and libs.
#
bindir = ('./bin', './sbin', './lib', './usr/bin', './usr/sbin', './usr/lib')

for fi in gc.garbage:
  if fi.path.startswith(bindir):
    print(fi.path)
