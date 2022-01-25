#!/bin/bash

set -ex

# add /opt/bin to search path
export PATH=/opt/homebrew/bin/:$PATH

# cd script dir
cd "$(dirname "$0")" || exit
cd ..

GIT_ROOT=$(pwd)

# call release compile command, permission are hereby given by git
./Resources/compile.release.command clean

# go into git root
cd "$GIT_ROOT" || exit

TIMESTAMP=""

# check if file exists at ./build/.lastbuild.timestamp
if [ -f "./build/.lastbuild.timestamp" ]; then
    # read content into TIMESTAMP
    TIMESTAMP=$(cat "./build/.lastbuild.timestamp")
fi

# remove leading and trailing space or newline for timestamp
TIMESTAMP=$(echo "$TIMESTAMP" | sed -e 's/^[ \t]*//' -e 's/[ \t]*$//')

# if timestamp is empty or less then 2 character, exit the script
if [ -z "$TIMESTAMP" ] || [ ${#TIMESTAMP} -lt 2 ]; then
    echo "Invalid timestamp for build, empty or less then 2 characters, abort!"
    exit 1
fi

BUILD_PRODUCT="$GIT_ROOT/build/Release-$TIMESTAMP"

# check if dir exists at build product, or abort
if [ ! -d "$BUILD_PRODUCT" ]; then
    echo "Build product not found, abort!"
    exit 1
fi

cd "$BUILD_PRODUCT"

# duplicate PackageBuilder
cp -r ./PackageBuilder ./AppStorePackageBuilder
cd AppStorePackageBuilder

# check Applications dir exists and contains one and only *.app folder
APP_CONTENT_COUNT=$(find ./Applications -maxdepth 1 -type d -name "*.app" | wc -l)
if [ "$APP_CONTENT_COUNT" -ne 1 ]; then
    echo "Invalid build product, APP_CONTENT_COUNT=$APP_CONTENT_COUNT abort!"
    exit 1
fi

# move applications to payload
mv Applications Payload

# zip payload
zip -r "chromatic.relsan.$TIMESTAMP.ipa" Payload # release sandboxed

cd "$GIT_ROOT/build" || exit

# remove artifact dir if found
if [ -d "artifact" ]; then
    rm -rf "artifact"
fi
mkdir artifact

# copy every file with deb extension inside build product into current dir
find "$BUILD_PRODUCT" -name "*.deb" -exec cp {} ./artifact \;

# copy every file with ipa extension inside build product into current dir
find "$BUILD_PRODUCT" -name "*.ipa" -exec cp {} ./artifact \;

# get dir with *.dSYM inside 
DSYM_LOCATION=$(find "./Release-$TIMESTAMP/DerivedDataApp/Build/Products/Release-iphoneos/" -maxdepth 1 -type d -name "*.dSYM" | head -n 1)
zip -r0 "./artifact/$TIMESTAMP+dSYM.zip" "$DSYM_LOCATION"

# print artifact dir
echo "Artifacts [$(pwd)] :"
ls -la ./artifact

# check if CI is set to true
if [ "$CI" = "true" ]; then
    echo "build_timestamp=$TIMESTAMP" >> "$GITHUB_ENV"
fi

# done
