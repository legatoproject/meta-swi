DESCRIPTION = "QuIC Linux Kernel"
LICENSE = "GPLv2"

inherit kernel-src-install

# Determine linux version from sources
def determine_linux_version(d):
    repo_dir = d.getVar('LINUX_REPO_DIR', True)
    makefile_path = os.path.join(repo_dir, "Makefile")
    if not os.path.exists(makefile_path):
        raise Exception("Kernel Makefile doesn't exist at %s" % makefile_path)

    import re
    v = []
    with open(makefile_path) as f:
        r = re.compile("(VERSION|PATCHLEVEL|SUBLEVEL) = (\d+)")
        for line in f:
            m = r.match(line)
            if not m:
                continue

            v.append(m.group(2))
            if m.group(1) == "SUBLEVEL":
                break

    if len(v) != 3:
        raise Exception("Error while parsing Kernel Makefile %s: "
                        "%d sub-version(s) found instead of 3" % (makefile_path, len(v)))

    return ".".join(v)

LINUX_VERSION ?= "${@determine_linux_version(d)}"
PV = "${LINUX_VERSION}+git${GITSHA}"
PR = "r1"

do_install_append() {
    kernel_src_install
}
