#!/bin/bash

# Download and Install Java SDK 8 
# Author: Thiago Navarro - navarro.ime@gmail.com

SUDO="sudo "
JAVA_TAR_GZ_FILE=jdk-8u241-linux-x64.tar.gz

do_print(){
  echo ""
  echo "=========================="
  echo "$1"
  echo "=========================="
  echo ""      
}
java_download(){
    do_print "Downloading JAVA 8 SDK ..."
    cd /tmp/
    wget --no-cookies \
    --no-check-certificate \
    --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    http://download.oracle.com/otn-pub/java/jdk/8u241-b07/1f5b5a70bf22433b84d0e960903adac8/jdk-8u241-linux-x64.tar.gz
   
    do_print "Download completed"

}
JAVA_SHA256SUM="419d32677855f676076a25aed58e79432969142bbd778ff8eb57cb618c69e8cb"
if [[ -f "/tmp/jdk-8u241-linux-x64.tar.gz" ]] 
then 
    JAVA_SHA256SUM_LOCAL=`sha256sum /tmp/jdk-8u241-linux-x64.tar.gz | awk '{print $1}'`
    echo ""
    echo "java sha256sum local $JAVA_SHA256SUM_LOCAL"
    echo "java sha256sum remote $JAVA_SHA256SUM" 
    echo ""
    if [[ "$JAVA_SHA256SUM" != "$JAVA_SHA256SUM_LOCAL" ]]
    then
       do_print "Invalid sha256sum!!"
       do_print "Removing file and download again..."
       rm -v /tmp/jdk-8u241-linux-x64.tar.gz
       java_download 
    fi
else
    java_download
fi

# Create java installation folder
JAVA_INSTALL_PATH=/usr/local/etc/java
$SUDO mkdir -p -v $JAVA_INSTALL_PATH
# Extract java
cd /tmp
$SUDO tar -xzf jdk-8u241-linux-x64.tar.gz
# Update $PATH env
do_print "Update \$PATH env"
echo 'export PATH='$JAVA_INSTALL_PATH':$PATH' >> ~/.bashrc
