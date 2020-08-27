#!/bin/bash

echo Starting fakeroot
echo $(pwd)

chown -R root:wheel ./Applications/Saily.app
chmod -R 755 ./Applications/Saily.app
chmod +s ./Applications/Saily.app/Saily

chown root:wheel ./bin/openApplication
chmod +x ./bin/openApplication

rm ./fakeroot.sh
dpkg-deb -Zgzip -b . ./$BUILDNAME