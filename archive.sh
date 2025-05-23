#!/bin/bash
set -e
xcodebuild archive -archivePath package/archive -scheme LiveContainer -project LiveContainer.xcodeproj -sdk iphoneos -arch arm64 -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
echo "fake signing..."
find package/archive.xcarchive/Products/Applications/LiveContainer.app -type d -path '*/Frameworks/*.framework' -exec ldid -Sentitlements.xml \{\} \;
ldid -Sentitlements.xml package/archive.xcarchive/Products/Applications/LiveContainer.app
echo "creating ipa..."
rm package/archive.xcarchive/Products/Applications/LiveContainer.app/LiveContainer
mv package/archive.xcarchive/Products/Applications package/Payload
cd package
zip -r LiveContainer.ipa Payload -x "._*" -x ".DS_Store" -x "__MACOSX"
cd ..
echo "sending ipa to iPhone via tailscale..."
tailscale file cp package/LiveContainer.ipa ${TAILSCALE_IPHONE_NAME}:
echo "cleaning up ..."
rm -rf package/archive.xcarchive package/Payload
echo "uploading..."
./upload.sh
