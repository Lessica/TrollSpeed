#!/bin/sh

# This script is used to generate the control file for the Debian package.
if [ $# -ne 1 ]; then
    echo "Usage: $0 <version>"
    exit 1
fi

VERSION=$1

# Strip leading "v" from version if present
VERSION=${VERSION#v}

# Create the layout directory
mkdir -p layout/DEBIAN

# Write the control file
cat > layout/DEBIAN/control << __EOF__
Package: ch.xxtou.hud
Name: HUD App
Version: $VERSION
Section: Tweaks
Depends: firmware (>= 13.0), mobilesubstrate (>= 0.9.7000), com.rpetrich.rocketbootstrap (>= 1.0.9)
Architecture: iphoneos-arm
Author: XXTouch Team.
Maintainer: XXTouch Team.
Description: Next generation XXTouch for iOS 13 and above.
__EOF__

# Set permissions
chmod 0644 layout/DEBIAN/control

# Write the Info.plist file
defaults write $(pwd)/layout/Applications/TrollSpeed.app/Info.plist CFBundleVersion $VERSION
defaults write $(pwd)/layout/Applications/TrollSpeed.app/Info.plist CFBundleShortVersionString $VERSION
plutil -convert xml1 $(pwd)/layout/Applications/TrollSpeed.app/Info.plist
