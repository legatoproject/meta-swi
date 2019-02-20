# The Python2 manifest includes '${libdir}/python2.7/encodings', and so pulls in
# everything under that directory: modules for supporting all sorts of rarely used
# character encodings. Let's remove it! We should keep at least utf-8, as well
# as the aliases module for mapping content types to codecs.

do_install_append() {
  encodings=${D}/usr/lib/python2.7/encodings

  if [ -e "$encodings" ] ; then
    find "$encodings" -type f | grep -v -E '/(utf_8|aliases)\.(py|pyc)$' | xargs rm -f
  fi
}
