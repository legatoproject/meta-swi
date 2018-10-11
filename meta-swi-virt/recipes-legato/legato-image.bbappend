do_compile_prepend() {
    export VIRT_TARGET_ARCH=${VIRT_ARCH}
}

select_legato_target() {
    if grep -q VIRT_TOOLCHAIN_DIR "${S}/targetDefs"; then
        export LEGATO_TARGET="virt"
    fi
}

