#!/usr/bin/env python3

import os
import sys
import argparse
import shutil
import re
import subprocess
from distutils import dir_util, errors

pj = os.path.join

self = sys.argv[0]
self_dir = os.path.dirname(self)
top_dir = pj("..", self_dir)


#
# Trivial class representing paths requiring canonicalization
#
class cpth:
    def __init__(self, path=""):
        self.path = path


#
# Specification of command line variables.
#
# This is a list of triplets:
#
#  [ name, default, description ]
#
# The default values specify the value used for the variable
# when the corresponding command line argument is missing.
# Furthermore, the default value specifies the type.

# If the default value is a list, then the variable is a list.  Occurrences of
# the corresponding argument on the command line are accumulated into a list.
# The default value must contain at least one element: the first element
# is a type class indicating the element type; the remaining elements
# specify the initial value for the list. For instance, [str] means
# "list of strings", and [int, 0] means list of strings, starting with
# [ 0, ...], others coming from the command line.
#
# If the default value is cpth(), it specifies a path which will be
# canonicalized: turned into absolute paths relative to the current
# working directory, with symbolic links resolved. An argument given
# to cpth is the default value; if it is missing the value is the
# empty string. Empty string values are not canonicalized.
#
varspec = [
    ["poky-dir", cpth(), "poky directory"],
    ["meta-oe-dir", cpth(), "meta-openembedded directory"],
    ["meta-swi-dir", cpth(), "meta-swi directory"],
    ["linux-repo-dir", cpth(), "Path to kernel tree"],
    ["distro", "poky-swi", "Distribution label, defaulting " "to poky-swi"],
    [
        "machine-type",
        "swi-mdm9x28",
        "Sierra machine type, defaulting " "to swi-mdm9x28",
    ],
    ["product", "", "Sierra product, e.g. ar758x"],
    ["build-dir", cpth("build"), "Build directory"],
    ["bitbake-tasks", 4, "# of tasks used by bitbake"],
    ["make-threads", 4, "# of jobs used by make"],
    ["enable-preempt-rt", False, "Enable preemptible kernel"],
    ["enable-legato", False, "Enable Legato build"],
    [
        "kernel-provider",
        "",
        "Name of kernel provider "
        "package. If omitted, it defaults "
        "to linux-yocto. If the Sierra "
        "machine type is swi-mdm9x15, "
        "this default value is also "
        "used. For other Sierra mdm9xxx "
        "machines, defaults to "
        "linux-quic.",
    ],
    ["enable-recovery-image", False, "Enable recovery build."],
    ["enable-extended-image", False, "Enable additional tools."],
    ["enable-debug-image", False, "Enable additional debug image."],
    ["enable-ima", False, "Build IMA-enabled image."],
    [
        "ima-config-file",
        "",
        "Path to IMA config file. " "This is used as-is, " "not canonicalized.",
    ],
    ["bitbake-flags", "", "Options to pass to BitBake."],
    ["enable-icecc", False, "Build using icecc."],
    ["enable-shared-sstate", False, "Enable shared BitBake sstate."],
    ["enable-prop-bin", False, "Enable proprietary Qualcomm " "binary packages."],
    ["enable-prop-src", False, "Enable proprietary Qualcomm " "source packages."],
    [
        "apps-proc-dir",
        cpth(),
        "Path to Qualcomm firmware " 'tree, usually an "apps_proc" ' "directory.",
    ],
    ["firmware-version", "", "Qualcomm Firmware version"],
    ["ar-yocto-path", cpth(), "Path to ar_yocto-cwe.tar.bz2 " "file."],
    ["enable-mangoh", False, "Enable mangOH layer."],
    ["enable-qemu", False, "Enable QEMU build."],
    [
        "cmdline-mode",
        False,
        "Do not execute build. Instead, "
        "launch a shell environment from "
        "which bitbake commands can be "
        "invoked, switched to the build "
        "directory.",
    ],
    ["debug-image", False, "Unsupported debug image. " "Use at your own risk."],
    [
        "build-toolchain",
        False,
        "Build the toolchain image, " "and only the toolchain image.",
    ],
    [
        "recipe-args",
        [str],
        "Additional BitBake variables put into layers.conf. Syntax of <str> values "
        "is <name>=<value>. Option may be repeated to specify multiple variables. "
        "Also, multiple variables can be specified in one option, separated by :: "
        "(double colon) as in --recipe-args=foo=bar::x=y.",
    ],
]


#
# main function
#
def main():
    parser = arg_parser_from_varspec(varspec)

    if len(sys.argv) == 1:
        msg("arguments required; use --help for a listing")
        sys.exit(0)

    ns = parser.parse_args()

    if ns.help:
        print()
        parser.print_help()
        print()
        sys.exit(0)

    check_tweak_vars(ns, parser.canon_path_vars)
    dump_opts(ns)

    if os.path.basename(os.path.realpath("/bin/sh")) != "bash":
        msg("ERROR: build requires /bin/sh to be GNU Bash")
        sys.exit(1)

    build_dir = ns.build_dir

    prepare_oe_build_env(ns)

    bblayers_conf = pj(build_dir, "conf/bblayers.conf")
    conf = read_conf(bblayers_conf)
    enable_oe_layers(conf, ns)
    enable_swi_layers(conf, ns)
    enable_layer(conf, pj(top_dir, "meta-mangoh"))
    write_conf(bblayers_conf, conf)

    local_conf = pj(build_dir, "conf/local.conf")
    lconf = read_conf(local_conf)
    tune_local_conf(lconf, ns)
    squeeze_blank_lines(lconf)
    write_conf(local_conf, lconf)

    sys.exit(do_build(ns))


def check_tweak_vars(ns, paths):
    check_tweak_ima(ns)
    canonicalize_paths(ns, paths)
    check_tweak_apps_proc(ns)
    check_tweak_product(ns)
    check_tweak_kernel_provider(ns)


def check_tweak_ima(ns):
    if ns.enable_ima and ns.ima_config_file == "":
        msg('"enable-ima" requires "ima-config-file"')
        sys.exit(1)
    if ns.ima_config_file != "":
        ns.enable_ima = True


def check_tweak_apps_proc(ns):
    apps_proc = ns.apps_proc_dir
    if apps_proc != "" and not os.path.exists(apps_proc):
        msg('WARNING: "apps-proc-dir" path "{apps_proc}" does not exist')


def check_tweak_product(ns):
    product = ns.product
    prod_fam = re.match(r"[^\d]*", product).group(0)
    if product != "" and prod_fam == "":
        msg("WARNING: product family calculated as blank")
    ns.product_family = prod_fam


def check_tweak_kernel_provider(ns):
    kern_prov = ns.kernel_provider

    if kern_prov == "":
        kern_prov = "linux-yocto"
        mach = ns.machine_type
        if mach.startswith("swi-mdm9") and mach != "swi-mdm9x15":
            kern_prov = "linux-quic"
        elif mach.startswith("swi-sdx55"):
            kern_prov = "linux-msm"

        ns.kernel_provider = kern_prov


#
# Enable OpenEmbedded layers
#
def enable_oe_layers(conf, ns):
    enable_layer_group(
        conf,
        ns.meta_oe_dir,
        ["meta-oe", "meta-networking", "meta-python", pj("..", "meta-gplv2")],
    )


def enable_swi_layers(conf, ns):
    mach = ns.machine_type
    meta_swi_dir = ns.meta_swi_dir
    prod = ns.product
    prod_fam = ns.product_family
    enable_prop_src = ns.enable_prop_src
    enable_prop_bin = ns.enable_prop_bin
    enable_prop = enable_prop_src or enable_prop_bin
    apps_proc = ns.apps_proc_dir
    fw_version = ns.firmware_version
    layer_list = []  # mix of strings (required layers) and lists (optional)

    # Non-proprietary SWI common layer:
    layer_list += ["common"]

    # Non-proprietary SWI machine and product layers:
    if mach.startswith("swi-virt-"):
        layer_list += ["meta-swi-virt"]
    elif mach.startswith("swi-mdm9") or mach.startswith("swi-sdx55"):
        layer_list += ["meta-swi-mdm9xxx", "meta-%s" % (mach)]

        if mach.startswith("swi-sdx55"):
            # Special meta-swi-em layers for sdx55:
            layer_list += [
                "../meta-swi-em/common",
                "../meta-swi-em/meta-swi-em9xxx",
                "../meta-swi-em/meta-swi-em9190",
            ]

        if prod != "":
            layer_list += [["meta-%s-%s" % (mach, prod)]]

        # If doing proprietary, change distro in order to alter SDKPATH
        if enable_prop:
            ns.distro = "poky-swi-ext"

    # Proprietary SWI common and machine layers
    if enable_prop:
        layer_list += [
            "../meta-swi-extras/common",
            "../meta-swi-extras/meta-%s" % (mach),
        ]

    # Proprietary SWI product layers
    if prod_fam != "":
        layer_list += [
            [
                "../meta-swi-%s/common" % (prod_fam),
                "../meta-swi-%s/meta-swi-%s" % (prod_fam, prod),
            ]
        ]

        if enable_prop:
            layer_list += [
                [
                    "../meta-swi-%s-extras/common" % (prod_fam),
                    "../meta-swi-%s-extras/meta-swi-%s-extras" % (prod_fam, prod),
                ]
            ]

            if enable_prop_src:
                layer_list += [
                    ["../meta-swi-%s-extras/meta-swi-%s-src" % (prod_fam, prod)]
                ]
            else:
                layer_list += [
                    ["../meta-swi-%s-extras/meta-swi-%s-bin" % (prod_fam, prod)]
                ]

    # Proprietary source layers
    if enable_prop_src:
        if apps_proc == "":
            msg('"apps-proc-dir" variable ("apps_proc" directory) is not set')
            sys.exit(1)

        if not os.path.isdir(pj(apps_proc, "qmi")):
            msg('"apps-proc-dir" variable {apps_proc} not valid location')
            msg('"apps-proc-dir" must point to "apps_proc" of firmware tree')
            sys.exit(1)

        msg("Workspace dir: %s" % (apps_proc))

        if fw_version != "":
            msg("Workspace version: %s" % (fw_version))

        layer_list += [
            "../meta-swi-extras/meta-swi-mdm9xxx-src",
            "../meta-swi-extras/meta-%s-src" % (mach),
        ]

        # Product-specific source and no-arch layers
        if prod != "":
            layer_list += [
                [
                    "../meta-swi-extras/meta-%s-%s-src" % (mach, prod),
                    "../meta-swi-extras/meta-%s-%s" % (mach, prod),
                ]
            ]

        # For sdx55 bring in layer list Yocto build
        if mach.startswith("swi-sdx55"):
            layer_list += [
                "../meta-swi-em-extras/common",
                "../meta-swi-em-extras/meta-swi-em9xxx-src",
                "../meta-swi-em-extras/meta-swi-em9190-src",
            ]
        # For mdm9x15 additional files are needed for the Yocto build
        elif mach == "swi-mdm9x15":
            copy_dir_pairs = [
                [
                    pj(apps_proc, "../modem_proc/sierra/src/dx/src/common"),
                    pj(apps_proc, "sierra/dx/common"),
                ],
                [
                    pj(apps_proc, "../modem_proc/sierra/src/dx/api/common"),
                    pj(apps_proc, "sierra/dx/common"),
                ],
                [
                    pj(apps_proc, "../modem_proc/sierra/src/qapi/src/common"),
                    pj(apps_proc, "sierra/qapi/common"),
                ],
                [
                    pj(apps_proc, "../modem_proc/sierra/src/nv/src/common"),
                    pj(apps_proc, "sierra/nv/common"),
                ],
                [
                    pj(apps_proc, "../modem_proc/sierra/src/nv/api/common"),
                    pj(apps_proc, "sierra/nv/common"),
                ],
            ]

            for src, dst in copy_dir_pairs:
                dircopy(src, dst)

            try:
                qcsi_common = pj(apps_proc, "sierra/qcsi/common")
                try:
                    removepath(qcsi_common)
                except OSError:
                    pass
                os.symlink("../qapi/common", qcsi_common)
            except Exception as exc:
                msg("creating symlink %s -> ../qapi/common: %s" % (qcsi_common, exc))
                msg("unable to provide qcsi common files from modem_proc")
                sys.exit(1)

    # Proprietary binary layers
    if enable_prop_bin:
        layer_list += [
            [
                "../meta-swi-extras/meta-swi-mdm9xxx-bin",
                "../meta-swi-extras/meta-%s-bin" % (mach),
            ]
        ]

        if mach.startswith("swi-sdx55"):
            # Special meta-swi-em-extras layers for sdx55:
            layer_list += [
                "../meta-swi-em-extras/common",
                "../meta-swi-em-extras/meta-swi-em9xxx-bin",
                "../meta-swi-em-extras/meta-swi-em9190-bin",
            ]

        if prod != "":
            layer_list += [["../meta-swi-extras/meta-%s-%s-bin" % (mach, prod)]]

    # enable all the layers
    enable_layer_group(conf, meta_swi_dir, layer_list)

    # determine Yocto machine (placed into ns, to be later installed layer.conf)

    def determine_yocto_mach(try_mach):
        # find machine configuration file among layers
        mach_conf = find_file_in_layer_group(
            "%s.conf" % (try_mach), meta_swi_dir, layer_list
        )
        if mach_conf:
            msg("machine config file found at: %s" % (mach_conf))
            if ns.enable_qemu:
                return "%s-qemu" % (try_mach)
            return try_mach
        return None

    if prod != "":
        if ns.enable_recovery_image:
            yocto_mach = determine_yocto_mach(
                "%s-%s-rcy" % (mach, prod)
            ) or determine_yocto_mach("%s-rcy" % (mach))
        else:
            yocto_mach = determine_yocto_mach(
                "%s-%s" % (mach, prod)
            ) or determine_yocto_mach(mach)
    else:
        yocto_mach = determine_yocto_mach(mach)

    if yocto_mach:
        msg("Yocto machine: %s" % (yocto_mach))
        ns.yocto_mach = yocto_mach  # later installed into layer.conf
    else:
        msg("Yocto machine not determined")


def tune_local_conf(lconf, ns):
    tune_local_conf_src_mirror(lconf, ns)
    tune_local_conf_ima(lconf, ns)
    tune_local_conf_fx30(lconf, ns)
    tune_local_conf_extra_opts(lconf, ns)
    tune_local_conf_kernel_provider(lconf, ns)
    tune_local_conf_icecc(lconf, ns)
    tune_local_conf_initramfs(lconf, ns)
    tune_local_conf_misc(lconf, ns)


def tune_local_conf_src_mirror(lconf, ns):
    if hasattr(ns, "yocto_mach"):
        set_option(lconf, "MACHINE", ns.yocto_mach)

    after_line = "#DL_DIR"

    # these options will appear in the reverse order relative
    # to these set_option statements, since we are inserting each
    # one after the matching line.

    set_option(lconf, "DISTRO", ns.distro, "=", after_line)
    set_option(lconf, "LINUX_REPO_DIR", ns.linux_repo_dir, "=", after_line)
    set_option(lconf, "WORKSPACE", ns.apps_proc_dir, "=", after_line)
    if hasattr(ns, "firmware_version"):
        set_option(lconf, "FW_VERSION", ns.firmware_version, "=", after_line)
    set_option(lconf, "BB_NO_NETWORK", "0", "=", after_line)

    if not get_option(lconf, "SOURCE_MIRROR_URL"):
        sstate_mirror_url = None
        local_dl = pj(top_dir, "downloads")
        if os.path.exists(local_dl):
            # local downloads directory
            src_mirror_url = "file://%s" % (local_dl)
        else:
            res_conf = read_conf("/etc/resolv.conf")
            if indexof(res_conf, lambda ln: "sierrawireless.local" in ln):
                # Internal SWI network
                yocto_major, yocto_minor = get_yocto_major_minor(ns)
                src_mirror_url = "http://get.legato/yocto/mirror/"

                # Use shared sstate, if configured
                if ns.enable_shared_sstate:
                    sstate_mirror_url = (
                        "http://get.legato/yocto/sstate/yocto-%s.$%s"
                        % (yocto_major, yocto_minor)
                    )
                    set_option(
                        lconf,
                        "SSTATE_MIRRORS",
                        [
                            "file://.*",
                            "%s/PATH;downloadfilename=PATH" % (sstate_mirror_url),
                        ],
                        "=",
                        after_line,
                    )
            else:
                # External network
                # Use official Yocto mirror
                src_mirror_url = "https://downloads.yoctoproject.org/mirror/sources/"

                # Use external SWI download mirror
                set_option(
                    lconf,
                    "PREMIRRORS_prepend",
                    [
                        "https?$://.*/.* https://get.legato.io/yocto/mirror/ \\n",
                        "git://.*/.*     https://get.legato.io/yocto/mirror/ \\n",
                    ],
                    "=",
                    after_line,
                )

        set_option(lconf, "BB_GENERATE_MIRROR_TARBALLS", "1", "=", after_line)
        set_option(lconf, "INHERIT", "own-mirrors", "+=", after_line)
        set_option(lconf, "SOURCE_MIRROR_URL", src_mirror_url, "?=", after_line)

        set_option(lconf, "BB_NUMBER_THREADS", ns.bitbake_tasks)
        set_option(lconf, "PARALLEL_MAKE", "-j " + str(ns.make_threads))

        set_option(lconf, "LEGATO_BUILD", ns.enable_legato)


def tune_local_conf_ima(lconf, ns):
    enable_ima = ns.enable_ima
    ima_conf_file = ns.ima_config_file

    ima_vars = [
        "IMA_CONFIG",
        "IMA_LOCAL_CA_X509",
        "IMA_PRIV_KEY",
        "IMA_PUB_CERT",
        "IMA_KERNEL_CMDLINE_OPTIONS",
        # Legato may need these:
        "IMA_PUBLIC_CERT",
        "IMA_PRIVATE_KEY",
        "IMA_SMACK",
    ]

    # Always set this option, because it may have been set to something
    # else previously. This will enable or disable the IMA build.
    set_option(lconf, "IMA_BUILD", enable_ima)

    if enable_ima:
        # If IMA is enabled, we know we have a config file, because
        # this was validated in check_tweak_ima. What we do here
        # is propagate selected values from an IMA config file (which is in shell
        # assignment format) into the local.conf.

        set_option(lconf, "ENABLE_IMA", "1")  # Legato needs this?
        set_option(lconf, "IMA_CONFIG", ima_conf_file)

        ima_conf = read_conf(ima_conf_file)

        for ln in ima_conf:
            # Handle three possible shell assignment syntaxes:
            # VAR='single quote', VAR="double quote" or VAR=unquoted
            # The value is subject to expansion.
            match0 = re.match("([A-Za-z_][A-Za-z_0-9]*)='(.*)'", ln)
            match1 = re.match('([A-Za-z_][A-Za-z_0-9]*)="(.*)"', ln)
            match2 = re.match("([A-Za-z_][A-Za-z_0-9]*)=(.*)\n", ln)

            if match0:
                var, val = match0.groups()
            elif match1:
                var, val = match1.groups()
            elif match2:
                var, val = match2.groups()
            else:
                var = None

            if var:
                xval = os.path.expandvars(val)
                if ("\\" in xval) or ("$" in xval) or ('"' in xval) or ("'" in xval):
                    msg("%s: in the shell line %s" % (ima_conf_file, ln))
                    msg(
                        "%s: cannot fully expand syntax: %s -> %s"
                        % (ima_conf_file, val, xval)
                    )
                    sys.exit(1)
                os.environ[var] = xval
                if var in ima_vars:
                    set_option(lconf, var, xval)
    else:
        # Unset everything. If not unset, some of these variables
        # could create problems later on in the build, because
        # they may get out of sync.
        set_option(lconf, "ENABLE_IMA", "0")
        set_option(lconf, "IMA_CONFIG", "")
        for var in ima_vars:
            set_option(lconf, var, "")


def get_yocto_major_minor(ns):
    poky_dir = ns.poky_dir
    yocto_tag = proc_output(
        [
            "git",
            "--git-dir=%s/.git" % (poky_dir),
            "describe",
            "--tags",
            "--match=yocto-*",
        ]
    )
    return re.match(r"yocto-(\d+).(\d+)", yocto_tag).groups()


def tune_local_conf_fx30(lconf, ns):
    if ns.product == "fx30":
        set_option(lconf, "ENABLE_FX30", True)
    else:
        set_option(lconf, "ENABLE_FX30", "")


def tune_local_conf_extra_opts(lconf, ns):
    extras = ns.recipe_args
    for extra in extras:
        for var_val in extra.split("::"):
            if "=" not in var_val:
                print('%s: value %s in "recipe-args" missing "="' % (self, var_val))
                sys.exit(1)
            var, val = var_val.split("=", 1)
            set_option(lconf, var, val)


def tune_local_conf_kernel_provider(lconf, ns):
    set_option(lconf, "PREFERRED_PROVIDER_virtual/kernel", ns.kernel_provider)


def tune_local_conf_icecc(lconf, ns):
    if ns.enable_icecc:
        if not get_option(lconf, "ICECC_PARALLEL_MAKE"):
            set_option(lconf, "INHERIT", "icecc", "+=")
            set_option(lconf, "ICECC_PARALLEL_MAKE", "-j 20")
            set_option(
                lconf,
                "ICECC_USER_PACKAGE_BL",
                " ".join(
                    [
                        "ncurses e2fsprogs libx11 gmp",
                        "libcap perl busybox lk libgpg-error libarchive",
                    ]
                ),
            )


def tune_local_conf_initramfs(lconf, ns):
    mach = ns.machine_type

    if mach.startswith("swi-mdm"):
        mdm_only_mach = mach[4:]
        set_option(lconf, "INITRAMFS_IMAGE_BUNDLE", "1")
        if ns.enable_recovery_image:
            set_option(lconf, "INITRAMFS_IMAGE", "mdm-image-recovery")
        else:
            set_option(lconf, "INITRAMFS_IMAGE", "%s-image-initramfs" % (mdm_only_mach))
    elif mach.startswith("swi-sdx55"):
        set_option(lconf, "INITRAMFS_IMAGE_BUNDLE", "1")
        set_option(lconf, "INITRAMFS_IMAGE", "mdm-image-initramfs")
    elif mach.startswith("swi-virt"):
        set_option(lconf, "INITRAMFS_IMAGE_BUNDLE", "1")
        set_option(lconf, "INITRAMFS_IMAGE", "swi-virt-image-initramfs")


def tune_local_conf_misc(lconf, ns):
    # Extended image
    enable_ext = ns.enable_extended_image

    set_option(lconf, "EXT_SWI_IMG", enable_ext)

    if enable_ext:
        # Not supported for deployment for various reasons, warn the users.
        msg("warning: You are building a debug image not intended for deployment.")
        msg("warning: Use it at your own risk.")

    # Firmware Path
    set_option(lconf, "FIRMWARE_PATH", ns.ar_yocto_path)

    # Remove GNUTLS
    set_option(lconf, "PACKAGECONFIG_remove", "gnutls")

    # Set PACKAGE_CLASSES
    set_option(lconf, "PACKAGE_CLASSES", "package_ipk")


def prepare_oe_build_env(ns):
    if inside_oe_env_do(ns, "") != 0:
        msg("unable to initialize OE build environment")
        sys.exit(1)


def do_build(ns):
    build_dir = ns.build_dir
    bb_flags = ns.bitbake_flags
    mach = ns.machine_type
    dev_or_min = "dev" if ns.debug_image else "minimal"

    os.chdir(build_dir)

    def bitbake(target):
        msg("bitbaking %s" % (target))
        return inside_oe_env_do(ns, "bitbake %s %s" % (bb_flags, target))

    status = 0
    if ns.cmdline_mode:
        status = inside_oe_env_do(ns, "/bin/bash")
    elif ns.build_toolchain:
        msg("build toolchain (for %s)" % (mach))
        status = bitbake("meta-toolchain-swi")
    else:
        msg("build image of %s rootfs (for %s)" % (dev_or_min, mach))
        if mach.startswith("swi-mdm"):
            mdm_only_mach = mach[4:]
            if ns.enable_recovery_image:
                status = bitbake("%s-image-recovery" % (mdm_only_mach))
            else:
                status = bitbake("%s-image-%s" % (mdm_only_mach, dev_or_min))
        elif mach.startswith("swi-sdx"):
            status = bitbake("mdm-image-minimal")
        elif mach.startswith("swi-virt"):
            status = bitbake("swi-virt-image-%s" % (dev_or_min))
        else:
            status = bitbake("core-image-%s" % (dev_or_min))

    if ns.enable_debug_image:
        if mach.startswith("swi-") and ns.enable_recovery_image:
            bitbake("debug-image")

    return status


def inside_oe_env_do(ns, sh_command):
    build_dir = ns.build_dir
    poky_dir = ns.poky_dir
    silent = " > /dev/null" if sh_command != "" else ""
    cmd = ". %s/oe-init-build-env %s%s; %s" % (poky_dir, build_dir, silent, sh_command)
    return subprocess.call(cmd, shell=True)


def flex_int(x):
    return int(x, 0)


#
# Convert the varspec into an arparse argument parser.
# We take the liberty of adding a canon_path_vars property to the parser,
# which holds the names of variables that are paths needing canonicalizaton.
#
def arg_parser_from_varspec(vs):
    parser = argparse.ArgumentParser(usage="%(prog)s [options]", add_help=False)
    paths = []

    # Let's have only --help not -h.
    parser.add_argument(
        "--help",
        dest="help",
        default=False,
        const=True,
        action="store_const",
        help="You're looking at it!",
    )

    for s in vs:
        name, dfl = s[0], s[1]
        oname = "--" + name
        noname = "--no-" + name
        nsname = name.replace("-", "_")
        desc = s[2] if len(s) >= 3 else None

        if isinstance(dfl, bool):
            parser.add_argument(
                oname,
                dest=nsname,
                default=dfl,
                const=True,
                action="store_const",
                help=desc,
            )
            parser.add_argument(
                noname, dest=nsname, default=dfl, const=False, action="store_const"
            )
        elif isinstance(dfl, str):
            parser.add_argument(
                oname, dest=nsname, default=dfl, metavar="<str>", type=str, help=desc
            )
        elif isinstance(dfl, cpth):
            parser.add_argument(
                oname,
                dest=nsname,
                default=dfl.path,
                metavar="<path>",
                type=str,
                help=desc,
            )
            paths.append(nsname)
        elif isinstance(dfl, int):
            parser.add_argument(
                oname,
                dest=nsname,
                default=dfl,
                metavar="<int>",
                type=flex_int,
                help=desc,
            )
        elif isinstance(dfl, list):
            parser.add_argument(
                oname,
                dest=nsname,
                default=dfl[1:],
                metavar=("<int>" if dfl[0] == int else "<str>"),
                type=dfl[0],
                action="append",
                help=desc,
            )
        else:
            print("%s: bad varspec entry: %s" % (self, name))
            sys.exit(1)

    parser.canon_path_vars = paths

    return parser


def canonicalize_paths(ns, path_keys):
    for k in path_keys:
        v = getattr(ns, k)
        if isinstance(v, cpth):
            v = v.path
        if v != "":
            setattr(ns, k, os.path.realpath(v))
        else:
            setattr(ns, k, v)


def dump_opts(ns):
    print("\n%s: building with these options:\n" % (self))
    for ent in vars(ns):
        print("  %s:" % (ent), getattr(ns, ent))


#
# Eliminate all leading and trailing blank lines,
# and reduce any runs of inner blank lines each
# into a single blank line.
#
def squeeze_blank_lines(conf):
    i = 0
    while i < len(conf):
        if conf[i] == "\n":
            if i == 0:
                del conf[i]
                continue
            elif i == len(conf) - 1:
                del conf[i]
                break
            elif conf[i + 1] == "\n":
                del conf[i]
                continue
        i = i + 1


def read_conf(conf_path):
    with open(conf_path) as f:
        return list(f)


def write_conf(conf_path, conf):
    with open(conf_path, "w") as f:
        f.write("".join(conf))


def indexof(iterable, predicate, start=0, end=None):
    for i in range(start, end or len(iterable)):
        if predicate(iterable[i]):
            return i
    return None


def rindexof(iterable, predicate, start=0, end=None):
    ri = None
    for i in range(start, end or len(iterable)):
        if predicate(iterable[i]):
            ri = i
    return ri


def enable_layer(conf, layer_path, previous_layer=None):
    def contains_previous(ln):
        return previous_layer in os.path.split(ln.strip())

    # index of BBLAYERS ?= ... line
    bbs = indexof(conf, lambda ln: ln.startswith("BBLAYERS "))
    # index of closing '  "' line.
    bbe = indexof(conf, lambda ln: ln.startswith('  "'), bbs)

    layer_path = os.path.realpath(layer_path)

    # if layer_path is already listed, bail
    dupe = " %s " % (layer_path)
    if indexof(conf, lambda ln: dupe in ln, bbs + 1, bbe):
        msg("have layer: %s" % (layer_path))
        return

    # if layer doesn't exist, bail
    if not os.path.exists(layer_path):
        msg("layer %s is a nonexistent path; skipping" % (layer_path))
        return

    # insert before previous layer, or else last
    ins = bbe

    if previous_layer:
        pins = rindexof(conf, contains_previous, bbs + 1, bbe)
        if pins:
            ins = pins + 1
        else:
            msg("previous layer %s not found;" % (previous_layer))
            msg("... inserting %s at the end" % (layer_path))

    # insert it before the closing line
    conf.insert(ins, "  %s \\\n" % (layer_path))
    msg("new layer: %s" % (layer_path))


#
# Hacky routines for getting and setting variables in a BitBake .conf
# file.
#
# conf is the verbatim configuration file, represented as a list of lines that
# include the terminating newline. Everything is in there including comments.
#
# The val parameter may be a string value, or a list of strings.
# If the list is empty, the variable will be deleted, if found.
# A list of one string is treated as if it were just a string parameter.
#
# Multi-line assignments in the file indicated by continuation backslashes
# are properly recognized and replaced.
#
# The after paramter indicates a preferred location for the variable
# in the event that the variable is newly added. If it is omitted, the
# new variable goes at the end. Otherwise, a line containing the
# after parameter as a substring is found, and the item is inserted
# after that line.
#
def set_option(conf, var, val, op="=", after=None):
    idx, end = find_variable(conf, var, after)

    # The slice conf[idx:end] now denotes the item to be replaced
    # If the item doesn't exist, the slice conf[len:len] denotes
    # the spot just after the end of the list; replacing this
    # causes it to be appended. Replacing it with [] does nothing.

    if isinstance(val, bool):
        val = "true" if val else "false"

    if isinstance(val, list):
        if len(val) == 1:
            val = val[0]

    if isinstance(val, list):
        if len(val) == 0:
            new = []
        else:
            new = (
                ['%s %s "\\\n' % (var, op)]
                + ["    %s \\\n" % (el) for el in val]
                + ['"\n']
            )
    else:
        new = ['%s %s "%s"\n' % (var, op, val)]

    msg('setting %s %s "%s"' % (var, op, val))
    conf[idx:end] = new


def get_option(conf, var):
    idx, end = find_variable(conf, var)

    if idx == end:
        return None

    if idx + 1 == end:
        # single-line item
        return re.search(r'"([^"]*)"', conf[idx]).group(1)

    out = re.search(r'"([^"]*)\\', conf[idx]).group(1)
    for i in range(idx + 1, end - 1):
        out += conf[i][0:-2]
    out += re.match(r'([^"]*)"', conf[end - 1]).group(1)
    return out


def find_variable(conf, var, after=None):
    key1 = "%s =" % (var)
    key2 = "%s ?=" % (var)
    key3 = "%s ??=" % (var)
    key4 = "%s +=" % (var)

    idx = indexof(
        conf,
        lambda ln: ln.startswith(key1)
        or ln.startswith(key2)
        or ln.startswith(key3)
        or ln.startswith(key4),
    )

    if idx:
        if conf[idx].endswith("\\\n"):
            # multi-line item: ends with first line not ending in backslash
            end = indexof(conf, lambda ln: not ln.endswith("\\\n"), idx + 1)
            if end:
                end = end + 1
            else:
                end = len(conf)
        else:
            # one-line item
            end = idx + 1
    else:
        idx = len(conf)
        if after:
            aidx = indexof(conf, lambda ln: after in ln)
            if aidx:
                idx = aidx + 1
        end = idx

    return idx, end


def enable_layer_if_exists(conf, layer_path, previous_layer=None):
    if os.path.exists(layer_path):
        enable_layer(conf, layer_path, previous_layer)


#
# Enable related group of layers.
#
# These are layers which share a common directory prefix,
# passed as the prefix parameter. The prefix is added to
# every layer in the layer_list.
#
# The layer_list is a mixture of strings and lists of strings.
# The top-level strings are required layers; the strings
# encapsulated in lists are optional layers:
#
# [ 'path/required_layer_1', 'path/required_layer_2',
#   [ 'path/to/optional_layer_1', 'another_optional' ],
#   'required_layer_3' ... ]
#
def enable_layer_group(conf, prefix, layer_list):
    for layer in layer_list:
        if isinstance(layer, list):
            for opt_layer in layer:
                enable_layer_if_exists(conf, pj(prefix, opt_layer))
        else:
            enable_layer(conf, pj(prefix, layer))


#
# Find a file given by filename among the specified layers.
# The prefix and layer_list parameter are exactly like
# in the enable_layer_group_function.
# Each layer directory is recursively scanned in search
# of the file.
#
def find_file_in_layer_group(filename, prefix, layer_list):
    def find_machine_conf(path):
        if os.path.isdir(path):
            for entry in scantree(path):
                if entry.is_file() and entry.name == filename:
                    return entry.path

    for layer in layer_list:
        if isinstance(layer, list):
            for opt_layer in layer:
                found = find_machine_conf(pj(prefix, opt_layer))
                if found:
                    return found
        else:
            found = find_machine_conf(pj(prefix, layer))
            if found:
                return found


def dircopy(src, dst):
    try:
        dir_util.copy_tree(src, dst)
    except errors.DistutilsFileError as err:
        msg("unable to copy directory %s -> %s: %s" % (src, dst, err))
        sys.exit(1)


def scantree(path):
    for entry in os.scandir(path):
        if entry.is_dir(follow_symlinks=False):
            yield from scantree(entry.path)
        else:
            yield entry


def removepath(path):
    if os.path.isdir(path) and not os.path.islink(path):
        shutil.rmtree(path)
    elif os.path.exists(path):
        os.remove(path)


def proc_output(args):
    bytestr = subprocess.check_output(args)
    return bytestr.decode("utf-8")


def msg(arg):
    print("%s: %s" % (self, arg))


main()
