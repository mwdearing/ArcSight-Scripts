#!/usr/bin/env bash
export CURRENT=/opt/arcsight/connectors/connector_1/current; \
export TH=CDF_HOSTNAME.com_9093; \
export CA_CERT=re_ca.cert.pem; \
export STORE_PASSWD=changeit; \
export STORE=/opt/arcsight/connectors/thub_store ; \
cd $CURRENT; \
mkdir -p $STORE; \
touch $STORE/$CA_CERT
# The certificate used here is gathered from the cdf-updateRE.sh 
cat << "EOF" >  $STORE/$CA_CERT
-----BEGIN CERTIFICATE-----
      <base64_here>
-----END CERTIFICATE-----
EOF

$CURRENT/jre/bin/keytool -importcert -file $STORE/$CA_CERT -alias CARoot -keystore $STORE/$TH.truststore.jks -storepass $STORE_PASSWD -noprompt
echo "Connector destination configuration:"

echo -n "Cert Store location: "
echo $STORE/$TH.truststore.jks
