# Set file attr for smack
set_file_attr(){
    for file in ${1}/*
    do
        if [ -d ${file} ]; then
            ${STAGING_DIR_NATIVE}/usr/bin/attr -L -S -s ${SMACK_ATTR_NAME} -V ${SMACK_ATTR_VALUE} ${file}
            set_file_attr ${file}
        elif [ -f ${file} -a ! -h ${file} ]; then
            ${STAGING_DIR_NATIVE}/usr/bin/attr -S -s ${SMACK_ATTR_NAME} -V ${SMACK_ATTR_VALUE} ${file}
        elif [ -f ${file} -a -h ${file} ]; then
            fd=$(readlink ${file} -f)
            if [ -e ${fd} ]; then
                ${STAGING_DIR_NATIVE}/usr/bin/attr -L -S -s ${SMACK_ATTR_NAME} -V ${SMACK_ATTR_VALUE} ${file}
            fi
        fi
    done
}

