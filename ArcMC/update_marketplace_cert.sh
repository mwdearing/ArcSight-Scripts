#!/usr/bin/env bash
# Grab latest certificate from Micro Focus Marketplace.
openssl s_client -showcerts -connect \
marketplace.microfocus.com:443 </dev/null 2>/dev/null \
| openssl x509 -out marketplace.microfocus.com.cer
