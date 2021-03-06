#!/bin/bash -x

KEY_CHAIN=ios-build.keychain
KEY_STORE=certs/android.keystore
KEY_PASS=travis

if [ -z "$P12_PASSWORD" ]; then
  echo "Error: Missing password for adding P12s"
  exit 1
fi

build_keychain() {
if [ "$TRAVIS_OS_NAME" = "linux" ]; then
  echo "No iOS keychain needed on linux"
  return
fi

security create-keychain -p $KEY_PASS $KEY_CHAIN
# Make the keychain the default so identities are found
security default-keychain -s $KEY_CHAIN
#list only this keyhain
security list-keychains -s $KEY_CHAIN #login.keychain
# Unlock the keychain
security unlock-keychain -p $KEY_PASS $KEY_CHAIN
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

security set-key-partition-list -S apple-tool:,apple: -s -k $KEY_PASS $KEY_CHAIN
security find-identity -p codesigning ~/Library/Keychains/$KEY_CHAIN

mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
cp -av profile/*.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
egrep --text -A1 UUID ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | egrep string
}

android_keystore() {
  rm -f $KEY_STORE
  for i in certs/android_*.p12; do
    echo "Importing key:" $i
    #keytool -importkeystore -deststorepass $KEY_PASS -destkeystore $KEY_STORE -srckeystore $i -srcstoretype PKCS12 -srcstorepass $P12_PASSWORD
    keytool -importkeystore -deststorepass $KEY_PASS -destkeypass $KEY_PASS \
      -destkeystore $KEY_STORE -srckeystore $i -srcstoretype PKCS12 -srcstorepass $P12_PASSWORD
  done
  keytool -list -keystore $KEY_STORE -storepass $KEY_PASS
}

encrypt_files() {
  for i in certs/*.p12 profile/*.mobileprovision ; do
    echo "Encrypting "  ${i}
    openssl aes-256-cbc -salt -a -e -pass pass:$OPENSSL_ENCRYPT_PASS -in $i -out $i.enc
  done
}
decrypt_files() {
  for i in certs/*.enc profile/*.enc ; do
    echo "Decrypting "  ${i%.*}
    openssl aes-256-cbc -salt -a -d -pass pass:$OPENSSL_ENCRYPT_PASS -in $i -out ${i%.*}
  done
}
