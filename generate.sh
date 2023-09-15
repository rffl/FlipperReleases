#!/usr/bin/env bash

# Cleanup
rm -rf flipper
rm -f flipper.tar.gz

# Get latest version published by Meta
REPO="facebook/flipper"
LATEST_TAG=$(curl -L https://github.com/facebook/flipper/releases/latest  | grep "facebook/flipper/releases/tag" -m 1 | sed "s/.*releases\/tag\///;s/\".*//")
TARBALL_URL="https://github.com/facebook/flipper/archive/refs/tags/$LATEST_TAG.tar.gz"

SOURCE_TAR="flipper.tar.gz"
curl -L -o $SOURCE_TAR $TARBALL_URL

mkdir -p flipper
tar -xf $SOURCE_TAR -C flipper --strip-components=1

# Apply patches
pushd flipper
git init && git add . && git commit -m "Original source"


git remote add flipperUpstream https://github.com/markholland/flipper.git
git fetch flipperUpstream m1-universal

git cherry-pick --keep-redundant-commits \
e4039306d0819f7b3668fb2a9a4a581ce5dc1bab \
a87d3ccc9c19c26bcfe99e154b0aae1d05ba95d9 \
52d78d94528a1dc8d607fb735e02a9df0480008b \
420f53802558bfa49d13ba5c96cf33d5b7392fc2 \
b10207f9bdf9eeb0bd08534cc5a64c6f9cec7597 \
6768711253d080a2509b81b963c885327337b34f \
230bb37a055139156e964e705d2dc25966c2d4a9

pushd desktop
if grep -Fxq "@electron/universal" package.json
then
    echo "electron/universal is present in the resolutions"
else
    echo "Patching electron/universal in the resolutions"
    resolutions='"resolutions": {'
    electron_resolution='"@electron/universal": "1.3.4",'
    sed -i '' "/$resolutions/ a\\
    $electron_resolution
    " package.json
fi

# To fix some errors shows in CI, suggesting that repository key should be present in package.json
build_info='"homepage":'
repository_info='"repository": "facebook/flipper",'

sed -i '' "/$build_info/ a\\
  $repository_info
" package.json

yarn install
yarn build --mac-dmg
