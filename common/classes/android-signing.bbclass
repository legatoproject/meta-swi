# common signing variables

ANDROID_SIGNING_DIR = "${STAGING_DIR_NATIVE}/usr/share/android-signing"

DEPENDS += "android-signing-native openssl-native"


def sign_table(d, table, privkey):
    import subprocess

    if not os.path.isabs(privkey):
        # Key name: build absolute path to android-signing key
        privkey = d.getVar("ANDROID_SIGNING_DIR") + "/security/" + \
                           privkey + ".pk8"

    if not os.path.exists(privkey):
        raise Exception("Key file '%s' not found" % privkey)

    # Use openssl to sha256-sign table with private key
    command = "openssl dgst -sha256 -sign %s" % privkey
    if not privkey.lower().endswith(".pem"):
        # Need extra argument for DER-formatted keys
        command = command + " -keyform DER"

    subproc = subprocess.run(command.split(), input = str.encode(table), \
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if not 0 == subproc.returncode:
        raise Exception("sign_table with: \n%s\ntable:\n%s\nerror %d:%s\n" % \
                       (command, table, subproc.returncode, subproc.stderr))

    signature = subproc.stdout
    return signature


def pack_android_metadata(table, signature):
    import io, struct

    # Android-verity metadata creation as per reference:
    # https://nelenkov.blogspot.com/2014/05/using-kitkat-verified-boot.html
    magic = 0xb001b001
    version = 0
    bsize = 32 * 1024

    # Use memory buffer to create metadata
    length = 0
    buf = io.BytesIO()

    # Pack and write header
    header = struct.pack("<II", magic, version)
    length += buf.write(header)

    # Write signature
    length += buf.write(signature)

    # Write table size (in bytes)
    table_size = struct.pack("<I", len(table))
    length += buf.write(table_size)

    # Write dm table entry
    length += buf.write(str.encode(table))

    # Pad with zeros
    padding = "\0" * (bsize - length)
    length += buf.write(str.encode(padding))

    # Rewind and return buffer
    buf.seek(0)
    return buf.read()


def generate_android_metadata(d, table, privkey):
    signature = sign_table(d, table,privkey)
    return pack_android_metadata(table, signature)


def verity_key_id(d, cert):
    import subprocess

    if 0 == len(cert):
        raise Exception("Bad certificate name: %s" % cert)

    if not os.path.isabs(cert):
        # Certificate name: build absolute path to android-signing cert
        cert = d.getVar("ANDROID_SIGNING_DIR") + "/security/" + \
                         cert + ".x509.pem"
    if not os.path.exists(cert):
        raise Exception("Certificate file '%s' not found" % cert)

    searchfor="Subject Key Identifier"
    command = "openssl x509 -in %s -noout -text |" \
              " grep -A1 \"%s\" | grep -v \"%s\" | tr -d \": \\n\\r\"" % \
              (cert, searchfor, searchfor)

    subproc = subprocess.run(command, shell=True, \
                             stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if not 0 == subproc.returncode:
        raise Exception("get_signature_key_id with: \n%s\nerror %d:%s\n" %
                       (command, subproc.returncode, subproc.stderr))

    # Return just the last 8 characters
    key_id = subproc.stdout.decode().lower()
    if 0 == len(key_id):
        raise Exception("Zero-length key id")
    key_id = "id:" + key_id[-8:]
    return key_id


# sign image and append Android signature
android_signature_add() {
    local image_type=$1
    local unsigned_image_path=$2
    local signed_image_path=$3
    local key=$4
    local attestation_ca=$5
    local root_ca=$6

    # android-signing's boot_signer requires java from host machine
    export PATH=$PATH:/usr/bin

    ${ANDROID_SIGNING_DIR}/verity/boot_signer $image_type \
                ${unsigned_image_path} \
                ${ANDROID_SIGNING_DIR}/security/${key}.pk8 ${ANDROID_SIGNING_DIR}/security/${key}.x509.pem \
                ${signed_image_path}

    # append cert chain if specified
    if [ -f ${ANDROID_SIGNING_DIR}/security/${attestation_ca} ]; then
      cat ${ANDROID_SIGNING_DIR}/security/${attestation_ca} >> ${signed_image_path}
    fi
    if [ -f ${ANDROID_SIGNING_DIR}/security/${root_ca} ]; then
      cat ${ANDROID_SIGNING_DIR}/security/${root_ca} >> ${signed_image_path}
    fi
}

