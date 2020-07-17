#!/bin/bash

cd "$(dirname "$0")"
rm -rf Buildtime
mkdir Buildtime

mkdir ./Buildtime/Packages
cp $DEB_LOCATION ./Buildtime/Packages/

mkdir -p ./Buildtime/www/ress
cp ./Resources/index.html ./Buildtime/www
cp ./Resources/icon.png ./Buildtime/www/CydiaIcon.png
cp ./Resources/Release ./Buildtime/www/Release

cp ./Buildtime/Packages/*.deb ./Buildtime/www/ress/
cd ./Buildtime/www/
dpkg-scanpackages -m ./ress / > Packages
bzip2 -fks Packages

cd ../../

docker-compose down
docker-compose up -d