#!/bin/bash -x

KEY_CHAIN=ios-build.keychain

build_keychain() {
if [ "$TRAVIS_OS_NAME" = "linux" ]; then
  echo "No keys needed on linux"
  return
fi
if [ -z "$P12_PASSWORD" ]; then
  echo "Error: Missing password for adding P12s"
  exit 1
fi

security create-keychain -p travis $KEY_CHAIN
# Make the keychain the default so identities are found
security default-keychain -s $KEY_CHAIN
#list only this keyhain
security list-keychains -s $KEY_CHAIN #login.keychain
# Unlock the keychain
security unlock-keychain -p travis $KEY_CHAIN
# Set keychain locking timeout to 3600 seconds
security set-keychain-settings -t 3600 -u $KEY_CHAIN

for i in certs/*.cer; do
  echo "Importing cert:" $i
  security import $i -k $KEY_CHAIN -T /usr/bin/codesign
done
for i in certs/ios_*.p12; do
  echo "Importing key:" $i
  # hide password
  { set +x; } 2>/dev/null
  security import $i -k $KEY_CHAIN -P $P12_PASSWORD -T /usr/bin/codesign
  set -x;
done

security set-key-partition-list -S apple-tool:,apple: -s -k travis $KEY_CHAIN
security find-identity -p codesigning ~/Library/Keychains/$KEY_CHAIN

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp -av profile/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
egrep --text -A1 UUID ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | egrep string
}

encrypt_files() {
  for i in certs/*.p12 profile/*.mobileprovision ; do
    openssl aes-256-cbc -salt -a -e -pass pass:$OPENSSL_ENCRYPT_PASS -in $i -out $i.enc
  done
}
decrypt_files() {
  for i in certs/*.enc profile/*.enc ; do
    echo "Decrypting "  ${i%.*}
    openssl aes-256-cbc -salt -a -d -pass pass:$OPENSSL_ENCRYPT_PASS -in $i -out ${i%.*}
  done
}
