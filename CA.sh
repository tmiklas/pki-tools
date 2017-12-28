#!/bin/bash
#
# (c) @tomaszmiklas 2017
# License: GPL v3
#
# because "PKI is hard"
# so let's work smarter, not harder
#

openssl genrsa -des3 -out ca.key 4096
openssl req -new -x509 -days 365 -key ca.key -out ca.crt

