inherit tar-runtime


FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-SWI-ltp-cmdlib_sh.patch \
            file://0006-SWI-creat08-open10-setgid.patch"

rm_tests() {
    CAUSE="missing mkfs"
    for t in access06 \
             acct01 \
             chmod06 \
             chown04 \
             creat06 \
             fchmod06 \
             fchown04 \
             ftruncate04 \
             lchown03 \
             link08 \
             mkdir03 \
             mknod07 \
             mmap16 \
             rename11 \
             rmdir02 \
             umount2_01 \
             umount2_02 \
             umount2_03 \
             utime06; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    CAUSE="missing ipcs"
    for t in msgctl08 \
             msgctl09; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    CAUSE="missing hostid"
    for t in gethostid01; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    CAUSE="missing bash"
    for t in rwtest01 \
             rwtest02 \
             rwtest03 \
             rwtest04 \
             rwtest05; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    CAUSE="read-only file-system"
    for t in open08; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    CAUSE="open of dev fails. \/tmp is mounted with nodev opts"
    for t in open11; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    CAUSE="SWI change ulimit -c 1024 to 2048"
    for t in abort01 kill11; do
        sed -i "s/^${t} ulimit -c 1024;${t}/${t} ulimit -c 2048;${t} #SWI ${CAUSE}/" "${S}/runtest/ltplite"
    done
}

do_patch[postfuncs] += "rm_tests"
