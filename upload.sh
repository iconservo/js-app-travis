#!/bin/sh -xe

if [[ -z "$HOCKEYAPP_TOKEN" ]]; then
    echo "Error: Missing Hockeyapp token"
    return
fi

upload_ios() {
TARGET=$APP_SHORT.adhoc.ipa
if [ ! -s $TARGET ]; then
  echo "Adhoc distribution file doesnt exist:" $TARGET
  return
fi
if [ -z "TRAVIS_COMMIT_MESSAGE" ] ; then
  MSG="Auto upload";
else
  MSG=$TRAVIS_COMMIT_MESSAGE
fi
echo "Uploading " $TARGET
curl  -H "X-HockeyAppToken: $HOCKEYAPP_TOKEN" \
  -F status=2 \
  -F notify=0 \
  -F notes="$MSG" \
  -F notes_type=0 \
  -F strategy=replace \
  -F "ipa=@$TARGET" \
  -F tags=ci \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEY_APP_ID_IOS/app_versions/upload
}
upload_android() {
TARGET=app-release.apk
if [ ! -s TARGET ]; then
  echo "Rel apk file doesnt exist:" $TARGET
  return
fi
curl  -H "X-HockeyAppToken: $HOCKEYAPP_TOKEN" \
  -F status=2 \
  -F notify=0 \
  -F notes="$MSG" \
  -F notes_type=0 \
  -F strategy=replace \
  -F "ipa=@$TARGET" \
  -F tags=ci \
  https://rink.hockeyapp.net/api/2/apps/$HOCKEY_APP_ID_ANDROID/
}
