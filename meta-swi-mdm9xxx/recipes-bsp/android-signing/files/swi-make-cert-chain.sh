#!/bin/bash
#
# Copyright (C) 2017 Sierra Wireless, Inc.
#

# Generates a public/private key pairs and cert chain for the following:
# RootCA
# AttestationCA
# Attestation
# Cert chain can be used in PKI environment

# self signed RootCA
openssl genrsa -out RootCA.key -f4 2048
openssl req -new -x509 -sha256 -key RootCA.key -out RootCA.pem -days 10000 -subj '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=AndroidROOT/emailAddress=android@android.com'

# AttestationCA key and cert (signed by RootCA)
openssl genrsa -out AttestationCA.key -f4 2048
openssl req -new -key AttestationCA.key -out AttestationCA.csr -days 10000 -subj '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=AndroidAttestCA/emailAddress=android@android.com'
openssl x509 -req -sha256 -in AttestationCA.csr -out AttestationCA.pem -CA RootCA.pem -CAkey RootCA.key -days 10000 -set_serial 5 -extfile v3.ext

# Attestation key and cert (signed by AttestationCA)
openssl genrsa -out Attestation.key -f4 2048
openssl req -new -key Attestation.key -out Attestation.csr -days 10000 -subj '/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=AndroidAttest/emailAddress=android@android.com'
openssl x509 -req -sha256 -in Attestation.csr -out Attestation.x509.pem -CA AttestationCA.pem -CAkey AttestationCA.key -days 10000 -set_serial 10 -extfile v3.ext

openssl x509 -inform PEM -in RootCA.pem -out RootCA.der -outform DER
openssl x509 -inform PEM -in AttestationCA.pem -out AttestationCA.der -outform DER
openssl x509 -inform PEM -in Attestation.x509.pem -out Attestation.der -outform DER

openssl pkcs8 -in RootCA.key -topk8 -outform DER -out RootCA.pk8 -nocrypt
openssl pkcs8 -in AttestationCA.key -topk8 -outform DER -out AttestationCA.pk8 -nocrypt
openssl pkcs8 -in Attestation.key -topk8 -outform DER -out Attestation.pk8 -nocrypt

# RootCA.pem can be used to generate swi-keys.cwe:
# swi-key-cwe.sh testkey/RootCA.pem
