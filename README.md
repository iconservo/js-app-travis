# js-app-travis

[![Build Status](https://travis-ci.org/iconservo/js-app-travis.svg?branch=master)](https://travis-ci.org/iconservo/js-app-travis)

Shell scripts to create a Ionic/Cordova app from scratch, add all common plugins, add platforms, and build iOS and Android each in development, distribution and release configuration.

- [_vars.sh_](vars.sh) - sets all required env vars to configure build and distribution. App name, version etc.
- _keychain.sh_ - builds MacOS signing keychain from provided profile and certs file. Imports everything from _certs_ and _profile_ dirs
- _build.sh_ - creates Ionic app skeleton, configures it, and triggers native builds
- _upload.sh_ - publishes builds to HockeyApp and Testflight
- _travis.sh_ - travis run script that calls the above in order, overriding specific variables as necessary
- [_home.ts_](home.ts) - Simple Ionic page to verify all included plugins functioning in the target build

Shell scripts are structured as functions, so it's easy to run and rerun individual steps for local debugging as needed. To use locally:

Load all variables and functions into shell:

`>$ source vars.sh && source build.sh`

Customize/override as needed:

`>$ export BUILD_DIR=attempt1 && export APP_TEMPLATE=sidemenu`

Launch the main build script:

`>$ main_build`

Re-run just iOS development build step:

`>$ build_ios_dev`

After modifying the scripts, make sure to reload it by doing `source build.sh` again

# Travis

Travis needs a few secrets set on the build:
- **AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY** - AWS access key pair to upload to S3 buckets for deployment and artifacts storage.
- **HOCKEYAPP_TOKEN** - Hockeyapp upload-enabled API token
- **P12_PASSWORD** - P12 files password, to import into keychain
- **OPENSSL_ENCRYPT_PASS** - password to decrypt P12 and mobileprovision files using openssl. Use `encrypt_files` from keychain.sh to encrpyt them before committing.

# Control variables

buil.sh looks for `BUILD_IOS`, `BUILD_ANRDOID` variables to decide if respective native builds should be run, and `FULL_BUILD` to decide if all plugins and platforms should be installed - as this is a slow process.
