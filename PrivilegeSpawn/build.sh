#!/bin/bash

set -ex

# cd script dir
cd "$(dirname "$0")" || exit

# delete build dir if exists
if [ -d "build" ]; then
    rm -rf build
fi

# create build dir
mkdir build

# go into build dir 
cd build || exit

CONFIGURATION=Release

# if DEBUG found in second parameter, set CONFIGURATION to Debug
if [ "$1" == "DEBUG" ]; then
    CONFIGURATION=Debug
fi

xcodebuild \
    -project "../rootspawn.xcodeproj" \
    -scheme "rootspawn" \
    -configuration $CONFIGURATION \
    -archivePath ./build.xcarchive \
    -sdk iphoneos \
    -derivedDataPath ./ \
    ENABLE_BITCODE=NO CODE_SIGNING_ALLOWED=NO \
    CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGN_ENTITLEMENTS="" CODE_SIGNING_ALLOWED="NO" \
    GCC_GENERATE_DEBUGGING_SYMBOLS=YES STRIP_INSTALLED_PRODUCT=NO \
    COPY_PHASE_STRIP=NO UNSTRIPPED_PRODUCT=NO \
    clean archive

# look for binary in archive dir and copy to build dir
cp -f ./build.xcarchive/Products/Applications/rootspawn.app/rootspawn rootspawn

# remove the codesign of binary
codesign --remove ./rootspawn

# sign binary with ldid
ldid -S../sign.plist rootspawn

echo "Complied at $(pwd)/rootspawn"
