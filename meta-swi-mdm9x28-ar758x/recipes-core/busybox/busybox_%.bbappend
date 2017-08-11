do_install_prepend(){
    if grep -q "CONFIG_SYSLOGD=y" ${B}/.config; then
        echo "local0.* /var/log/swiapp_messages" >> ${WORKDIR}/syslog.conf
    fi
}
