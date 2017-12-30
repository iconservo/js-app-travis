#!/bin/bash -xe

source vars.sh

export APP_BUILD_NUMBER=$TRAVIS_BUILD_NUMBER
export BUILD_DIR=build

source keychain.sh
source build.sh
source upload.sh

decrypt_files
build_keychain
main_build

upload_ios
upload_android
