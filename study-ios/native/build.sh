#!/usr/bin/env bash
# Builds an UNSIGNED StudyTogether.ipa. Run from anywhere; output: study-ios/StudyTogether.ipa
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> Selecting Xcode"
for x in /Applications/Xcode_16.2.app /Applications/Xcode_16.1.app /Applications/Xcode_16.0.app /Applications/Xcode_16.app; do
  if [ -d "$x" ]; then sudo xcode-select -s "$x"; break; fi
done
xcodebuild -version

echo "==> Installing JS deps (Capacitor + plugins)"
npm install --no-audit --no-fund

echo "==> Installing xcodegen + ldid"
brew install xcodegen ldid

echo "==> Copying web app into the native project"
rm -rf native/gen && mkdir -p native/gen
cp -R www native/gen/public
cp capacitor.config.json native/gen/capacitor.config.json

echo "==> Generating Xcode project"
cd native
xcodegen generate

echo "==> Building (unsigned)"
rm -rf "$ROOT/build"
set +e
xcodebuild \
  -project StudyTogether.xcodeproj \
  -scheme App \
  -configuration Release \
  -sdk iphoneos \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$ROOT/build" \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  build > "$ROOT/xcodebuild.log" 2>&1
STATUS=$?
set -e
if [ $STATUS -ne 0 ]; then
  echo "================ BUILD FAILED: compiler errors ================"
  grep -E "error:|error :" "$ROOT/xcodebuild.log" | sort -u | head -40 || true
  echo "================ last 60 log lines ================"
  tail -60 "$ROOT/xcodebuild.log"
  exit $STATUS
fi

APP="$ROOT/build/Build/Products/Release-iphoneos/App.app"
test -d "$APP"

echo "==> Embedding Screen Time entitlement (re-signing tools such as Sideloadly/AltStore read it)"
ldid -SApp.entitlements "$APP/App" || echo "ldid step skipped"

echo "==> Packaging IPA"
rm -rf "$ROOT/Payload" "$ROOT/StudyTogether.ipa"
mkdir "$ROOT/Payload"
cp -R "$APP" "$ROOT/Payload/"
(cd "$ROOT" && zip -qry StudyTogether.ipa Payload && rm -rf Payload)
ls -lh "$ROOT/StudyTogether.ipa"
