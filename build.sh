#!/bin/sh

# This script is used to build the TrollSpeed app and create a tipa file with Xcode.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Set GITHUB_WORKSPACE to home directory if not set
if [ -z "$GITHUB_WORKSPACE" ]; then
    GITHUB_WORKSPACE="$HOME"
fi

# Build using Xcode
xcodebuild clean build archive \
-scheme TrollSpeed \
-project TrollSpeed.xcodeproj \
-configuration Release \
-sdk iphoneos \
-destination 'generic/platform=iOS' \
-archivePath TrollSpeed \
CODE_SIGNING_ALLOWED=NO \
THEOS="$GITHUB_WORKSPACE/theos" | xcpretty

chmod 0644 Resources/Info.plist
cp supports/entitlements.plist TrollSpeed.xcarchive/Products
cd TrollSpeed.xcarchive/Products/Applications || exit
codesign --remove-signature TrollSpeed.app
cd - || exit
cd TrollSpeed.xcarchive/Products || exit
mv Applications Payload
ldid -Sentitlements.plist Payload/TrollSpeed.app
chmod 0644 Payload/TrollSpeed.app/Info.plist
zip -qr TrollSpeed.tipa Payload
cd - || exit
mkdir -p packages
mv TrollSpeed.xcarchive/Products/TrollSpeed.tipa packages/TrollSpeed+AppIntents16_$VERSION.tipa
