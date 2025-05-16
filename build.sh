#!/bin/bash
xcodebuild build -scheme LiveContainer -project LiveContainer.xcodeproj -sdk iphoneos -arch arm64 -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
