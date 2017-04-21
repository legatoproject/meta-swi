This package will provide necessary image signing tool
based on AndroidVerifiedBootSignature

1. Default dev keys:
- security/verity.pk8 -- private key used to sign LK, kernel and other images
- security/verity.x509.pem -- certificate including public key

2. To generate a new set of key:
- make sure openssl is installed on your Linux host.
- use the make_key script to generate a new key pair:
make_key mykey '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=Android/emailAddress=android@android.com'
don't input password, then mykey.pk8 and mykey.x509.pem will be generated in
current folder.
- Copy the *.pk8 and *.x509.pem file to security/verity.* so that they will be
  used to build signed images

3. Key CWE file to be injected to device: swi-keys.cwe. Secure boot will be enabled
after the CWE file is loaded into the device. Once it is loaded, it cannot be
removed or replaced.
- To re-generate the CWE file after a new key pair is generated, please run
  the script swi-key-cwe.sh
