#!/bin/bash -xe

source vars.sh

export APP_BUILD_NUMBER=$TRAVIS_BUILD_NUMBER
export BUILD_DIR=build

source keychain.sh
source build.sh
source upload.sh

run_build() {
decrypt_files
build_keychain
main_build

upload_ios
upload_android
}

prepare_artifacts() {
# clean out decrypted files
rm -rf certs/ profile/
mkdir -p build_artifacts
#package up the whole build dir
tar czf /tmp/build.travis-$TRAVIS_JOB_NUMBER-job.tgz $TRAVIS_BUILD_DIR
mv /tmp/build.travis-$TRAVIS_JOB_NUMBER-job.tgz build_artifacts
#copy key config files
cp -v build/config.xml build/package.json build/ionic.config.json build/package-lock.json build_artifacts
#build products
cp -v build/*.ipa build/*.apk build_artifacts
tar cvzf build_artifacts/ipa.travis-$TRAVIS_JOB_NUMBER-job.tgz build/*.ipa build/*.apk
}
