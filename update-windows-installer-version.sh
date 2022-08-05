#!/bin/bash
version=`cat ./src/main/resources/VERSION`
echo "version is $version"
letterFreeVersion=`echo $version | sed -e "s/v//g"`
echo "letter free version is $letterFreeVersion"
echo "Update launch4j.cfg.xml"
sed -i "s/{version}/$letterFreeVersion/g" ./launch4j.cfg.xml
echo "Update install.nsi"
sed -i "s/{version}/$letterFreeVersion/g" ./install.nsi
