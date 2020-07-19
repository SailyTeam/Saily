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
TIMESTAMP=$(date +%s)
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
ORIG_VERSION=$(grep -i "^Version: " ./DEBIAN/control)
NEW_VERSION="${ORIG_VERSION:9}-$TIMESTAMP"
echo $NEW_VERSION
awk "!/^Version: /" ./DEBIAN/control | tee ./DEBIAN/control
printf "Version: ${NEW_VERSION}\n" >> ./DEBIAN/control
echo -en '\n' >> ./DEBIAN/control
chmod 0775 ./DEBIAN/* 

echo "* Code sign..."
ldid -SApplications/$APP_NAME.app/CodeSign.AfterJailbreak.plist ./Applications/$APP_NAME.app/$APP_NAME
find ./Applications/$APP_NAME.app/Frameworks -exec ldid -S {} &> /dev/null + || true

echo "* Building..."
dpkg-deb -Zgzip -b . ./$APP_NAME-Baker-$TIMESTAMP.deb
mkdir $SAFELOCATION/temps/build/
cp ./*.deb $SAFELOCATION/temps/build/
dpkg -I $SAFELOCATION/temps/build/$APP_NAME-Baker-$TIMESTAMP.deb

echo "Bake completed with result $SAFELOCATION/temps/build/$APP_NAME-Baker-$TIMESTAMP.deb"

echo ""
echo "---"
echo "Lakr Aream @Lakr233 2020-07"