# FX30 variation needs some additional config.
KBUILD_DEFCONFIG_SNIPPETS_append := " ${S}/arch/arm/configs/mdm9607-fx30_defconfig \
                                      ${THISDIR}/files/mdm9607-fx30.cfg \
                                    "
# Tell preprocessor that it needs to handle FX30 additions.
export EXTRA_DTC_CPP_FLAGS = " -DCONFIG_SIERRA_FX30"
