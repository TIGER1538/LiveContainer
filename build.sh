#!/bin/bash
xcodebuild archive -archivePath package/archive -scheme LiveContainer -project LiveContainer.xcodeproj -sdk iphoneos -arch arm64 -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
echo "fake signing..."
find package/archive.xcarchive/Products/Applications/LiveContainer.app -type d -path '*/Frameworks/*.framework' -exec ldid -Sentitlements.xml {};
ldid package/archive.xcarchive/Products/Applications/LiveContainer.app
echo "creating ipa..."
mv package/archive.xcarchive/Products/Applications package/Payload
zip -r package/LiveContainer.ipa package/Payload -x "._*" -x ".DS_Store" -x "__MACOSX"
echo "sending ipa to iPhone via tailscale..."
tailscale file cp package/LiveContainer.ipa ${TAILSCALE_IPHONE_NAME}:
echo "cleaning up ..."
rm -rf package/archive.xcarchive package/Payload
