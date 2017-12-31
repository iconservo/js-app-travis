#!/bin/sh -xe

if [[ -z "$HOCKEYAPP_TOKEN" ]]; then
    echo "Error: Missing Hockeyapp token"
    return
fi

if [ -z "TRAVIS_COMMIT_MESSAGE" ] ; then
  MSG="Auto upload";
else
  MSG=$TRAVIS_COMMIT_MESSAGE
fi

upload_ios() {
TARGET=$APP_SHORT.adhoc.ipa
if [ ! -s $TARGET ]; then
  echo "Adhoc distribution file doesnt exist:" $TARGET
  return
fi
echo "Uploading " $TARGET
set -x
curl  -H "X-HockeyAppToken: $HOCKEYAPP_TOKEN" \
  -F status=2 \
  -F notify=0 \
  -F notes="$MSG" \
  -F notes_type=0 \
  -F strategy=replace \
  -F "ipa=@$TARGET" \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEY_APP_ID_IOS/app_versions/upload
set +x
}
upload_android() {
TARGET=app-release.apk
if [ ! -s $TARGET ]; then
  echo "Rel apk file doesnt exist:" $TARGET
  return
fi
set -x
curl  -H "X-HockeyAppToken: $HOCKEYAPP_TOKEN" \
  -F status=2 \
  -F notify=0 \
  -F notes="$MSG" \
  -F notes_type=0 \
  -F strategy=replace \
  -F "ipa=@$TARGET" \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEY_APP_ID_ANDROID/app_versions/upload
set +x
}
