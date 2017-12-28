#!/bin/bash
#
# (c) @tomaszmiklas 2017
# License: GPL v3
#
# because "PKI is hard"
# so let's work smarter, not harder
#

# create initial serial if missing
if [ ! -s serial ]; then
  echo 01 > serial
fi

if [ -z $1 ]; then
  echo "Usage: $0 <client CN>"
  exit 1
fi

# autoincrement serial
SERIAL=$((`cat serial` + 1))

# generate key
openssl genrsa -des3 -out ${1}.key 4096

# remove password from the key, otherwise services (web server, etc) will ask for it at boot, or fail to boot
openssl rsa -in ${1}.key -out ${1}-NOPASS.key

# create client CSR
openssl req -new -key ${1}-NOPASS.key -out ${1}.csr

# self-sign
openssl x509 -req -days 365 -in ${1}.csr -CA ca.crt -CAkey ca.key -set_serial ${SERIAL} -out ${1}.crt && echo ${SERIAL} > serial

# convert to PKCS12
# only no-password version, it's still protected with export password
#openssl pkcs12 -export -clcerts -in ${1}.crt -inkey ${1}.key -out ${1}.p12
openssl pkcs12 -export -clcerts -in ${1}.crt -inkey ${1}-NOPASS.key -out ${1}-NOPASS.p12

# merge into single PEM - use if needed
#echo openssl pkcs12 -in ${1}-NOPASS.p12 -out ${1}-NOPASS.pem -clcerts
