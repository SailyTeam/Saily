#!/bin/bash

set -ex

# add /opt/bin to search path
export PATH=/opt/homebrew/bin/:$PATH

# cd script dir
cd "$(dirname "$0")" || exit
cd ..

GIT_ROOT=$(pwd)

# assert that Chromatic.xcworkspace exists
if [ ! -e "Chromatic.xcworkspace" ]; then
    echo "Chromatic.xcworkspace not found!"
    exit 1
fi

# if build not exists create it
if [ ! -e "build" ]; then
    mkdir build
fi
cd build || exit

# run license scan at Resources/compile.license.py
python3 "$GIT_ROOT/Resources/compile.license.py"

TIMESTAMP="$(date +%s)"

# make a dir depending on timestamp
WORKING_ROOT="Development-$TIMESTAMP"

# if WORKING_ROOT exists, delete it
if [ -e "$WORKING_ROOT" ]; then
    rm -rf "$WORKING_ROOT"
fi

# create WORKING_ROOT
mkdir "$WORKING_ROOT"
cd "$WORKING_ROOT" || exit

WORKING_ROOT=$(pwd)
echo "Starting build at $WORKING_ROOT"

# xcodebuild and echo to xcpretty
xcodebuild -workspace "$GIT_ROOT/Chromatic.xcworkspace" \
 -scheme Chromatic -configuration Debug \
 -derivedDataPath "$WORKING_ROOT/DerivedDataApp" \
 -destination 'generic/platform=iOS' \
 clean build \
 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \
 | xcpretty

xcodebuild -project "$GIT_ROOT/PrivilegeSpawn/rootspawn.xcodeproj" \
 -scheme rootspawn -configuration Debug \
 -derivedDataPath "$WORKING_ROOT/DerivedDataExec" \
 -destination 'generic/platform=iOS' \
 clean build \
 CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \
 | xcpretty

mkdir PackageBuilder
cd PackageBuilder || exit

mkdir Applications
# copy build result .app to Applications
cp -r "$WORKING_ROOT/DerivedDataApp/Build/Products/Debug-iphoneos/chromatic.app" "./Applications/"

codesign --remove "./Applications/chromatic.app"
if [ -e "./Applications/chromatic.app/_CodeSignature" ]; then
    rm -rf "./Applications/chromatic.app/_CodeSignature"
fi
if [ -e "./Applications/chromatic.app/embedded.mobileprovision" ]; then
    rm -rf "./Applications/chromatic.app/embedded.mobileprovision"
fi

ldid -S"$GIT_ROOT/Application/Chromatic/Entitlements.plist" "./Applications/chromatic.app/chromatic"
plutil -replace "CFBundleDisplayName" -string "Alpha" "./Applications/chromatic.app/Info.plist"
plutil -replace "CFBundleIdentifier" -string "wiki.qaq.chromatic.alpha" "./Applications/chromatic.app/Info.plist"
plutil -replace "CFBundleShortVersionString" -string "$TIMESTAMP" "./Applications/chromatic.app/Info.plist"

# copy scaned license into chromatic.app/licenses
cp -r "$GIT_ROOT/build/License/ScannedLicense" "./Applications/chromatic.app/Bundle/ScannedLicense"

mkdir -p usr/sbin/
cp -r "$WORKING_ROOT/DerivedDataExec/Build/Products/Debug-iphoneos/rootspawn.app/rootspawn" "./usr/sbin/chromaticspawn"
codesign --remove "./usr/sbin/chromaticspawn"
ldid -S"$GIT_ROOT/PrivilegeSpawn/sign.plist" "./usr/sbin/chromaticspawn"

cp -r "$GIT_ROOT/Resources/DEBIAN" ./

sed -i '' "s/@@VERSION@@/2.1-DEV-$TIMESTAMP/g" ./DEBIAN/control

chmod -R 0755 DEBIAN

PKG_NAME="chromatic.dev.ci.$TIMESTAMP.deb"
dpkg-deb -b . "../$PKG_NAME"

echo "Finished build at $WORKING_ROOT"
echo "Package available at $WORKING_ROOT/$PKG_NAME"

open "$WORKING_ROOT"
