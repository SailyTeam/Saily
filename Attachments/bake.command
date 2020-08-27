#!/bin/bash

cd "$(dirname "$0")"
cd ../

echo "Starting build system for release"
rm -rf ./temps/Protein.xcarchive
mkdir ./temps
xcodebuild clean
xcodebuild -workspace Protein.xcworkspace -list
xcodebuild \
        clean archive \
        -workspace Protein.xcworkspace \
        -scheme Protein \
        -configuration Release \
        -archivePath ./temps/Protein.xcarchive \
        -UseModernBuildSystem=YES \
        -destination generic/platform=iOS \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGN_ENTITLEMENTS="" \
        CODE_SIGNING_ALLOWED="NO" \
        | \
        xcpretty

echo "Build completed, starting bake for DEBIAN system"

echo "* Loading payloads..."
APP_NAME="Saily"
SAFELOCATION=$(pwd)

rm -rf ./temps/bake
mkdir ./temps/bake
cd ./temps/bake

cp -r $SAFELOCATION/DEBIAN ./
mkdir -p bin && cp $SAFELOCATION/Attachments/openApplication ./bin/
mkdir -p ./Applications
cp -r $SAFELOCATION/temps/Protein.xcarchive/Products/Applications/$APP_NAME.app ./Applications/
cp -f $SAFELOCATION/Protein/CodeSign.AfterJailbreak.plist ./Applications/$APP_NAME.app/CodeSign.AfterJailbreak.plist

echo "* Sending timestamp..."
chmod +x $SAFELOCATION/Attachments/timingVersion
rm ./DEBIAN/control
$SAFELOCATION/Attachments/timingVersion $SAFELOCATION/DEBIAN/control ./DEBIAN/control ./timestamp
TIMESTAMP=$(cat ./timestamp)
rm ./timestamp
chmod 0775 ./DEBIAN/*

echo "* Code sign..."
ldid -SApplications/$APP_NAME.app/CodeSign.AfterJailbreak.plist ./Applications/$APP_NAME.app/$APP_NAME
find ./Applications/$APP_NAME.app/Frameworks -exec ldid -S {} &> /dev/null + || true

echo "* Building..."
export BUILDNAME=$APP_NAME-Baker-$TIMESTAMP.deb
cp $SAFELOCATION/Attachments/fakeroot.sh .
chmod +x ./fakeroot.sh
fakeroot ./fakeroot.sh

mkdir $SAFELOCATION/temps/build/
cp ./*.deb $SAFELOCATION/temps/build/
dpkg -I $SAFELOCATION/temps/build/$APP_NAME-Baker-$TIMESTAMP.deb

echo "Bake completed with result $SAFELOCATION/temps/build/$APP_NAME-Baker-$TIMESTAMP.deb"

echo ""
echo "---"
echo "Lakr Aream @Lakr233 2020-07"
