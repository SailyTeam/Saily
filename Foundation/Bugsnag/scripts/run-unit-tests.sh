#!/usr/bin/env bash

set -euo pipefail

declare "${@}"

xcresult=$(date '+BugsnagTests-%Y-%m-%d-%H-%M-%S.xcresult')

die() {
	status=$?
	echo "^^^ +++"
	mkdir -p logs
	[[ -f xcodebuild.log ]] && mv xcodebuild.log logs/
	[[ -d $xcresult ]] && zip -qr "logs/$xcresult.zip" "$xcresult"
	exit $status
}


echo "--- Analyze"

make analyze "$@" || die

rm -rf DerivedData


echo "--- Test"

xcrun simctl shutdown all
xcrun simctl erase all

XCODEBUILD_EXTRA_ARGS=(-resultBundlePath "$xcresult")

if [[ ("$PLATFORM" = iOS || "$PLATFORM" = tvOS) && "$OS" == 9.* ]]; then
	# BugsnagNetworkRequestPlugin requires iOS/tvOS 10 or later
	XCODEBUILD_EXTRA_ARGS+=("-skip-testing:BugsnagNetworkRequestPlugin-${PLATFORM}Tests")
fi

make test "$@" XCODEBUILD_EXTRA_ARGS="${XCODEBUILD_EXTRA_ARGS[*]}" || die

rm -rf "$xcresult"
