#!/bin/bash -xe
boot_project() {
  rm -rf $BUILD_DIR
  ionic start $BUILD_DIR $APP_TEMPLATE --bundle-id $APP_ID -n $APP_NAME --cordova
  cd $BUILD_DIR
  mkdir -p node_modules
  touch gulpfile.js
  cp ../home.ts src/pages/home/home.ts
}
configure_ionic(){
  ionic config set app_id $APP_ID
  ionic config set name "$APP_SHORT"
  ionic config set watchPatterns "[]"
}
add_tool_deps() {
  npm i --save-dev gulp
  npm i --save-dev cordova-config-cli
  npm i --save-dev json
  if [ "$BUILD_IOS" = "1" ]; then
  npm i --save-dev ios-deploy
  fi
  ionic integrations enable gulp
}
config_cordova(){
  JSON=./node_modules/.bin/json
  CN=./node_modules/.bin/cordova-config
  $JSON  -f package.json -I -e 'this.name="'$APP_SHORT'"'
  $JSON  -f package.json -I -e 'this.author="'"$APP_AUTHOR"'"'
  $JSON  -f package.json -I -e 'this.homepage="'$APP_AUTHOR_URL'"'
  $CN set name "$APP_SHORT"
  $CN set desc "$APP_NAME"
  $CN set author "$APP_AUTHOR" "$APP_AUTHOR_EMAIL" "$APP_AUTHOR_URL"
  $CN set version "$APP_VERSION"
  $CN set android-version $APP_BUILD_NUMBER
  $CN set ios-version $APP_BUILD_NUMBER
  $CN add xml '<allow-navigation href="*"/>'
  $CN add xml '<allow-navigation href="http://*/*"/>'
  $CN add xml '<allow-navigation href="https://*/*"/>'
  $CN add xml '<feature name="StatusBar"><param name="ios-package" value="CDVStatusBar" onload="true" /></feature>'
  $CN add xml '<icon src="resources/android/icon/drawable-xhdpi-icon.png"/>'
  # required for location plugin
  $CN add xml '<edit-config file="*-Info.plist" mode="merge" target="NSLocationWhenInUseUsageDescription"><string>Allow '$APP_SHORT' to access your location</string></edit-config>'
  $CN add preference keyboardDisplayRequiresUserAction false
  $CN add preference webviewbounce false
  $CN add preference UIWebViewBounce false
  $CN add preference DisallowOverscroll true
  $CN add preference ShowSplashScreenSpinner false
  $CN add preference SplashScreenDelay 1000
}
add_platforms() {
  ionic cordova platform add android
  ionic cordova platform add ios
}
add_plugins() {
# remove preinstalled webview
ionic cordova plugin rm cordova-plugin-ionic-webview
ADD="ionic cordova plugin add"
$ADD cordova-plugin-ble-central --variable BLUETOOTH_USAGE_DESCRIPTION="Allow $APP_SHORT to access bluetooth"
$ADD cordova-custom-config
$ADD cordova-plugin-app-version
$ADD cordova-plugin-console
$ADD cordova-plugin-device
$ADD cordova-plugin-file-transfer
$ADD cordova-plugin-geolocation --variable GEOLOCATION_USAGE_DESCRIPTION="Allow $APP_SHORT to access your location"
$ADD cordova-plugin-inappbrowser
$ADD cordova-plugin-network-information
$ADD cordova-plugin-screen-orientation
$ADD cordova-plugin-splashscreen
$ADD cordova-plugin-statusbar
$ADD cordova-plugin-whitelist
$ADD ionic-plugin-deeplinks --variable URL_SCHEME=$APP_DEEPLINK_URLSCHEME --variable DEEPLINK_SCHEME=https \
  --variable DEEPLINK_HOST=$APP_DEEPLINK_HOST --variable ANDROID_PATH_PREFIX="/"
$ADD ionic-plugin-keyboard
$ADD https://github.com/kaidokert/cordova-plugin-crosswalk-webview.git --variable XWALK_VERSION="23+" \
  --variable XWALK_LITEVERSION="xwalk_core_library_canary:17+" \
  --variable XWALK_COMMANDLINE="--disable-pull-to-refresh-effect" \
  --variable XWALK_MODE=embedded --variable XWALK_MULTIPLEAPK=true
$ADD phonegap-plugin-push@1 --variable SENDER_ID=$APP_PUSH_SENDER
$ADD cordova-plugin-camera --variable PHOTOLIBRARY_USAGE_DESCRIPTION="Allow $APP_SHORT to access your photos" \
  --variable CAMERA_USAGE_DESCRIPTION="Allow $APP_SHORT to access your camera"
$ADD cordova-plugin-wkwebview-engine
$ADD cordova-plugin-file
$ADD https://github.com/afurusawa/WifiWizard.git
}
add_npm_libs(){
  npm i crypto-js
  npm i d3
  npm i handlebars
  npm i http-status-codes
  npm i humanize-duration
  npm i lodash
  npm i moment
  npm i pluralize
  npm i pubnub
  npm i sort-by
  npm i trackjs
  npm i uuid
}
add_npm_devlibs() {
  npm i --save-dev tslint
  npm i --save-dev codelyzer
  npm i --save-dev karma-cli
  npm i --save-dev protractor
  npm i --save-dev webpack
  npm i --save-dev tslint-eslint-rules
}
build_ios_dev() {
  ionic cordova build ios --device --aot \
    --debug \
    -- -d --codeSignIdentity="iPhone Developer" --developmentTeam=$CODESIGN_TEAM \
    --provisioningProfile=$CODESIGN_PROFILE_DEV --packageType=development
  cp ./platforms/ios/build/device/$APP_SHORT.ipa $APP_SHORT.dev.ipa
}
build_ios_appstore() {
  ionic cordova build ios --device --aot \
    --release \
    --prod --optimizejs --minifyjs \
    -- -d --codeSignIdentity="$CODESIGN_ID" --developmentTeam=$CODESIGN_TEAM \
    --provisioningProfile=$CODESIGN_PROFILE_APPSTORE --packageType=app-store
  cp ./platforms/ios/build/device/$APP_SHORT.ipa $APP_SHORT.appstore.ipa
}
build_ios_adhoc() {
  ionic cordova build ios --device --aot \
    --release \
    --prod --optimizejs --minifyjs \
    -- -d --codeSignIdentity="$CODESIGN_ID" --developmentTeam=$CODESIGN_TEAM \
    --provisioningProfile=$CODESIGN_PROFILE_ADHOC --packageType=ad-hoc
  cp ./platforms/ios/build/device/$APP_SHORT.ipa $APP_SHORT.adhoc.ipa
}
build_android_dev(){
  ionic cordova build android --device --aot \
    --debug \
    -- -d -- --gradleArg=-PcdvBuildMultipleApks=false --gradleArg=-PcdvMinSdkVersion=14 \
    --alias=androiddebugkey --password=travis --storePassword=travis \
    --keystore=../certs/android.keystore --keystoreType=jks #--gradleArg=-debug
  cp -v ./platforms/android/app/build/outputs/apk/debug/app-debug.apk app-debug.apk
}
build_android_prod(){
  ionic cordova build android --device --aot \
    --prod --optimizejs --minifyjs \
    --release \
    -- -d -- --gradleArg=-PcdvBuildMultipleApks=false --gradleArg=-PcdvMinSdkVersion=14 \
    --alias=prod.key --password=travis --storePassword=travis \
    --keystore=../certs/android.keystore --keystoreType=jks #--gradleArg=-debug
  cp -v platforms/android/app/build/outputs/apk/release/app-release.apk app-release.apk
}
run_full_build() {
  time boot_project
  time configure_ionic
  time add_tool_deps
  time config_cordova

  # --adding plugins and platforms in different order gives different results
  # if plugins are added first, some native builds fail
  time add_platforms
  time add_plugins
  # --
  time add_npm_libs
  time add_npm_devlibs

  ionic doctor list

  if [ "$BUILD_IOS" = "1" ]; then
  time build_ios_dev
  time build_ios_appstore
  time build_ios_adhoc
  fi
  if [ "$BUILD_ANDROID" = "1" ]; then
  time build_android_dev
  time build_android_prod
  fi
}

run_micro_build() {
  time boot_project
  time configure_ionic
  time add_tool_deps
  time config_cordova
  if [ "$BUILD_IOS" = "1" ]; then
  time build_ios_dev
  fi
  if [ "$BUILD_ANDROID" = "1" ]; then
  time build_android_dev
  fi
}

main_build() {
if [ "$FULL_BUILD" = 1 ]; then
  echo "full build"
  time run_full_build
else
  echo "micro build"
  time run_micro_build
fi
}
