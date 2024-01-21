#!/bin/sh

xcodebuild clean build archive \
-scheme TrollSpeed \
-project TrollSpeed.xcodeproj \
-sdk iphoneos \
-destination 'generic/platform=iOS' \
-archivePath TrollSpeed \
CODE_SIGNING_ALLOWED=NO | xcpretty

cd TrollSpeed.xcarchive/Products/Applications
codesign --remove-signature TrollSpeed.app
cd -
cd TrollSpeed.xcarchive/Products
mv Applications Payload
zip -qr TrollSpeed.tipa Payload
cd -
mv TrollSpeed.xcarchive/Products/TrollSpeed.tipa .
