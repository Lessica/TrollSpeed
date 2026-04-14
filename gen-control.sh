#!/bin/sh

# This script is used to generate the control file for the Debian package.

# Read the version from the existing control file
VERSION=$(./get-version.sh) || exit 1

echo "Using version: $VERSION"

RAND_BUILD_STR=$(openssl rand -hex 4)

# Write the Info.plist file
defaults write $PWD/Resources/Info.plist CFBundleShortVersionString $VERSION
defaults write $PWD/Resources/Info.plist CFBundleVersion $RAND_BUILD_STR
plutil -convert xml1 $PWD/Resources/Info.plist
chmod 0644 $PWD/Resources/Info.plist

XCODE_PROJ_PBXPROJ=$PWD/TrollSpeed.xcodeproj/project.pbxproj
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" $XCODE_PROJ_PBXPROJ