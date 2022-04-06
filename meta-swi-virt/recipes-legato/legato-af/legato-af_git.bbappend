# Used by legato/targetFiles/virt/build.sh to build a Docker image
DEPENDS += "qemu-system-native"

do_compile:prepend() {
    export VIRT_TARGET_ARCH=${VIRT_ARCH}
}

select_legato_target() {
    if [ -e "${S}/targetDefs" ] && grep -q VIRT_TOOLCHAIN_DIR "${S}/targetDefs"; then
        export LEGATO_TARGET="virt"
    else
        export LEGATO_TARGET="$1"
    fi
}

