inherit tar-runtime


FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://0001-SWI-ltp-cmdlib_sh.patch \
            file://0002-SWI-add-ima-tests-in-ltplite.patch \
            file://0003-SWI-runltp-tmp-for-dd.patch \
            file://0005-SWI-runltplite-tmp-for-dd.patch"
SRC_URI += "http://downloads.sf.net/project/linux-ima/linux-ima/ltp-ima-standalone-v2.tar.gz;md5sum=92c2fbd58d7e22837b0ba525e3af3228 \
           "
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

    CAUSE="endless test"
    for t in readdir02; do
        sed -i "s/^\(${t} \)/#SWI ${CAUSE} #\1/g" "${S}/runtest/ltplite"
    done

    for t in fsync01; do
        sed -i "s,^\(${t} \),\1 TMPDIR="'${LTPROOT}/tmp '",g" "${S}/runtest/ltplite"
    done

    for t in mtest01 mtest01w; do
        sed -i "/${t} /s/-p80/-p99/g" "${S}/runtest/ltplite"
    done

    for t in access02 creat07 execve03 mmap03 mmap04 \
             syslog01 syslog02 syslog03 syslog04 syslog05 \
             syslog06 syslog07 syslog08 syslog09 syslog10; do
        sed -i "/${t} /s,^.*$,${t} if \$(grep -q ima_appraise=enforce /proc/cmdline); then TCID=${t} tst_brkm TCONF \"\" \"IMA enabled\"; else ${t}; fi," "${S}/runtest/ltplite"
    done

}

do_patch[postfuncs] += "rm_tests"

do_patch_ima_src() {
    ima_testsrc_dir=${S}/testcases/kernel/security/integrity/ima/src/
    cp -a ${WORKDIR}/ima-tests/* ${ima_testsrc_dir}
    sed -i '/^CC = .*/d' ${ima_testsrc_dir}/Makefile
    sed -i '/^CFLAGS = .*/d' ${ima_testsrc_dir}/Makefile
    sed -i 's,^DESTDIR = .*,DESTDIR = '${D}/${exec_prefix}',' ${ima_testsrc_dir}/Makefile
}
addtask do_patch_ima_src after do_patch
