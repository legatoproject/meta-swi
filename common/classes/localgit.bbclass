#
# Helper class to handle local checked out GIT repositories cleanly 
#

# Bring in the tip SHA fetch functionality to support git local repos fully.
inherit gitsha

# Automagically move ${S} and ${O} for the user.  They can further override it, but they shouldn't have to
# do anything for most cases- and they'd best know what they're doing when they do it.
S = "${WORKDIR}/${PN}"
O = "${WORKDIR}/${PN}-obj"

# We optionally allow fetching of additional files and directories,
# so we leave do_fetch intact. Recipes inheriting from this class
# can still stuff SRC_URI and fetch things.

# Before fetching, we install the source directory as a symbolic
# link from insider ${WORKDIR} to ${SRC_DIR} so that
# other stages for things like the autotools stuff works like it's supposed
# to without too many extra special interventions...

python do_fetch() {
    import shutil

    target = d.getVar("SRC_DIR", expand=True)
    workdir = d.getVar("WORKDIR", expand=True)
    pn = d.getVar("PN", expand=True)

    link = workdir + "/" + pn

    # Six lines of Python just to blow something away:
    if os.path.islink(link):
      os.remove(link)
    elif os.path.isdir(link): # isdir yields true for symlinks to directories
      shutil.rmtree(link)     # this doesn't like symlinks to directories
    elif os.path.exists(link):
      os.remove(link)

    os.symlink(target, link)
}

# Suppress do_unpack and do_patch logic.
# Local symlinked checkouts don't require unpacking and patching.
do_unpack () {
}

do_patch () {
}

# base.bbclass contains logic which checks for the
# exact situation we have created, namely ${S} != ${WORKDIR} and
# in that case it associates do_unpack with a 'cleandirs'
# flag value of "${S}". That has the effect of blowing off our symlink
# when do_unpack is dispatched with bb.build.exec_func,
# and that happens even if do_unpack is a blank action.
# I know what you're thinking, and no: the simple
#    do_unpack[cleandirs] = ""
# doesn't work; it has to be the following python snippet:
python () {
    d.setVarFlag('do_unpack', 'cleandirs', '')
}
