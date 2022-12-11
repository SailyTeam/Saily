#!/bin/bash

set -o errexit
set -o nounset


echo "--- Prepare"

trap "echo '^^^ +++'" ERR

xcode_version_major=$(xcodebuild -version | head -n1 | cut -d ' ' -f 2 | cut -d . -f 1)

dir=features/fixtures/carthage

mkdir -p "$dir"

repo=${BUILDKITE_REPO:-file://$(pwd)}
commit=${BUILDKITE_COMMIT:-$(git rev-parse HEAD)}

echo "git \"$repo\" \"$commit\"" > "$dir"/Cartfile

cd "$dir"

cat Cartfile


for platform in iOS macOS tvOS watchOS
do
	cmdline=("carthage" "update" "--platform" "$platform" "--log-path" "./carthage-${platform}.log")
	if [ "$xcode_version_major" -ge 12 ]
	then
		cmdline+=("--use-xcframeworks")
	fi
	echo "---" "${cmdline[@]}"
	"${cmdline[@]}"
done
