#!/bin/bash

cd "$(dirname "$0")"
cd ../

# cocoapods

FILE=/usr/local/bin/brew
if [ -f "$FILE" ]; then
    echo "$FILE exist"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

HOMEBREW_NO_AUTO_UPDATE=1 brew install cocoapods
pod install

# patching pods
patch -N ./Pods/WCDBOptimizedSQLCipher/src/os_unix.c ./Attachments/patch-sql-osunix.c.patch
patch -N ./Pods/LTMorphingLabel/LTMorphingLabel/LTEasing.swift ./Attachments/patch-LTMorphingLabel-LTEasing.patch

# packing CI elemetns
#rm ./CI-Pods.tar
#tar -cvf ./CI-Pods.tar ./Pods

# open
open ./*.xcworkspace
