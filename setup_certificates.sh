#!/bin/bash

if [ -d ./certs ]; then
SERVER_CONFIGURATION_MSG="It looks like you've already set up certificates.  

If you really want to generate the certificates again, first remove
the ./certs directory.

rm -rf ./certs";
  #exit;
else

mkdir certs

# generate service keystore
keytool -genkey -alias service -keyalg RSA -keystore certs/service.jks -storepass service -keypass service -keysize 2048 -dname CN=localhost -noprompt
echo "service" > certs/service.psw
export SERVICE_PASS=`cat certs/service.psw`

# generate client keystore
keytool -genkey -alias client -keyalg RSA -keystore certs/client.jks -storepass client -keypass client -keysize 2048 -dname CN=client -noprompt
echo "client" > certs/client.psw
export CLIENT_PASS=`cat certs/client.psw`

# configure client.jks to trust 'CN=localhost' (service.jks)
keytool -export -alias service -file certs/service.crt -keystore certs/service.jks -storepass ${SERVICE_PASS}
keytool -import -trustcacerts -alias service -file certs/service.crt -keystore certs/client.jks -storepass ${CLIENT_PASS} -noprompt

# configure service.jks to trust 'CN=client' (client.jks)
keytool -export -alias client -file certs/client.crt -keystore certs/client.jks -storepass ${CLIENT_PASS}
keytool -import -trustcacerts -alias client -file certs/client.crt -keystore certs/service.jks -storepass ${SERVICE_PASS} -noprompt

# double check
keytool -list -v -keystore certs/client.jks -storepass ${CLIENT_PASS}
keytool -list -v -keystore certs/service.jks -storepass ${SERVICE_PASS}


# set up web server (e.g., Tomcat) using your service.jks keystore
# make sure the path from Tomcat's root to the certificates is good
# supply passwords for keystore and truststore (private key)

SERVER_CONFIGURATION_MSG="# set up web server (e.g., Tomcat) using your service.jks keystore
# make sure the path from Tomcat's root to the certificates is good
# supply passwords for keystore and truststore (private key)

[conf/server.xml]
<Connector className=\"org.apache.coyote.tomcat4.CoyoteConnector\"
port=\"8443\" enableLookups=\"true\"
acceptCount=\"100\" connectionTimeout=\"20000\"
useURIValidationHack=\"false\" disableUploadTimeout=\"true\"
scheme=\"https\" secure=\"true\" SSLEnabled=\"true\"
keystoreFile=\"conf/service.jks\" keystorePass=\"<password>\"
truststoreFile=\"conf/service.jks\" truststorePass=\"<password>\"
clientAuth=\"true\" sslProtocol=\"TLS\"
/>"

# set up client

# extract public key from client.jks

keytool -export -rfc -keystore certs/client.jks -storepass ${CLIENT_PASS} -alias client -file certs/client.pem


# extract private key from client.jks

# convert from jks to pkcs12
keytool -importkeystore -srckeystore certs/client.jks -destkeystore certs/client.p12 -srcstoretype JKS -deststoretype PKCS12 -srcstorepass ${CLIENT_PASS} -deststorepass ${CLIENT_PASS} -srcalias client -destalias client -srckeypass ${CLIENT_PASS} -destkeypass ${CLIENT_PASS} -noprompt
 
# convert from pkcs12 to PEM formatted private key
openssl pkcs12 -in certs/client.p12 -out certs/client.key -passin pass:${CLIENT_PASS} -passout pass:${CLIENT_PASS}


# lock down keys and password files
chmod 400 certs/*.psw certs/*.key


# verify all went well first for public cert and then for private key
openssl x509 -in certs/client.pem -text -noout
openssl rsa -in certs/client.key -check -passin pass:${CLIENT_PASS}
fi

echo "

=======================
== NOTICE(S) ==========
";

if [ -f ./config.yml ]; then
CONFIG_MSG="It looks like you already have a config.yml.  

If you want to regenerate the default config.yml file, 
you must remove it first.

rm config.yml";

else

echo "---
:certificate:
  :password: ${CLIENT_PASS}
  :private: ./certs/client.key
  :public: ./certs/client.pub
  :trusted:
  - ./certs/service.pub
:wsdl:
  :path: /HelloWorld/Greetings?wsdl
  :domain: localhost
  :port: 8443

# props = {certificate: {
#   password: "some-password", 
#   private: "./certs/client.key",
#   public: "./certs/client.pub",
#   trusted: ["./certs/server.pub"]},
# wsdl:{
#   path: "/HelloWorld/Greeting?wsdl", 
#   domain: "localhost", 
#   port: 8443
#   }
# }
# 
# == save properties to file
# require 'yaml'
# File.open("config.yml", "w"){|f|
# f.write YAML::dump(props)
# }
#
# == load properties from file
# require 'yaml'
# config = YAML::load(IO.read("config.yml"))
" > config.yml;

CONFIG_MSG="A default config.yml has been created for you with values associated with the certificates just made.";
fi

if [ -n "${CONFIG_MSG}" ]; then
echo "=======================
${CONFIG_MSG}
";
fi

if [ -n "${SERVER_CONFIGURATION_MSG}" ]; then
echo "=======================
${SERVER_CONFIGURATION_MSG}
";
fi

echo "=======================
Done!
";

