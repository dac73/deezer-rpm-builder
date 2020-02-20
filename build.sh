#!/bin/bash
set -e

# Get latest exe version
DEEZER_LATEST=$(curl -sLI "https://www.deezer.com/desktop/download?platform=win32&architecture=x86" | grep 'https://www.deezer.com/desktop/download/artifact/win32/x86' | awk -F '/' '{print $NF}')

echo "Latest version is $DEEZER_LATEST"
read -r -p "Update? [Y/n]" response
response=${response,,} # tolower
if [[ $response =~ ^(no|n| ) ]] || [[ -z $response ]]; then
  exit
fi

ELECTRON_VERSION=6.1.7
DEEZER_VERSION=${DEEZER_LATEST}
DEEZER_BINARY=deezer.exe

# Download file
# TODO wget 'https://www.deezer.com/desktop/download?platform=win32&architecture=x86' -O deezer.exe

# Check for Deezer Windows installer
if [ "$1" == windows ] && ! [ -f $DEEZER_BINARY ]; then
  echo Deezer installer missing!
  echo Please download Deezer for Windows from \
    'https://www.deezer.com/desktop/download?platform=win32&architecture=x86' \
    and place the installer in this directory as $DEEZER_BINARY
  exit 1
fi

# Check for required commands
check-command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo Missing command: "$1"
    exit 1
  fi
}

commands=(
  node npm asar electron-packager electron-installer-redhat
  7z icns2png fakeroot rpm
)

for command in "${commands[@]}"; do
  check-command "$command"
done

# Setup the build directory
mkdir -p build

# Extract the Deezer executable
if ! [ -f "build/deezer/\$PLUGINSDIR/app-64.7z" ]; then
  7z x $DEEZER_BINARY -obuild/deezer
fi

# Extract the app bundle
if ! [ -f build/bundle/resources/app.asar ]; then
  7z x "build/deezer/\$PLUGINSDIR/app-32.7z" -obuild/bundle
fi

# Extract the app container
if ! [ -d build/app ]; then
  asar extract build/bundle/resources/app.asar build/app
fi

# Install NPM dependencies
if ! [ -f build/app/package-lock.json ]; then
  echo "Installing deps"

  # temp WO for testing, backup ems TODO: patch new version of mpris hopefully it will still work
  cp -r build/app/node_modules/electron-media-service out/
  # Remove existing node_modules
  rm -rf build/app/node_modules

  # Remove unsupported electron-media-service package
  sed -i '/electron-media-service/d' build/app/package.json
  sed -i '30i  \ \ \ \ "electron-media-service":"^0.2.2",' build/app/package.json #TODO: use jq

  # add MPRIS
  sed -i '30i  \ \ \ \ "mpris-service":"^2.1.0",' build/app/package.json #TODO: use jq

  # Configure build settings
  # See https://www.electronjs.org/docs/tutorial/using-native-node-modules
  export npm_config_target=$ELECTRON_VERSION
  export npm_config_arch=x64
  export npm_config_target_arch=x64
  export npm_config_disturl=https://electronjs.org/headers
  export npm_config_runtime=electron
  export npm_config_build_from_source=true

  HOME=~/.electron-gyp npm install --prefix build/app

  # wo TODO
  cp -r out/electron-media-service build/app/node_modules/
fi

# patch those files
prettier --write "build/app/build/*.js"
prettier --write "build/app/build/assets/cache/js/route-naboo*ads*.js"
cd build/app
# Fix crash on startup since 4.14.1 (patch systray icon path)
patch -p1 <"../../systray.patch" #TODO: fix this for openSUSE
# Disable menu bar
patch -p1 <"../../menu-bar.patch"

# Monkeypatch MPRIS D-Bus interface
patch -p1 <"../../0001-MPRIS-interface.patch" #TODO: update for new version of electron-media-service
cd ../../

# Convert Deezer.icns to PNG
if ! [ -f build/app/Deezer_512x512x32.png ]; then
  macos_icon="build/deezer/Deezer $DEEZER_VERSION/Deezer.app/Contents/Resources/Deezer.icns"
  if [ -f "$macos_icon" ]; then
    icns2png -x -s 512x512 "$macos_icon" -o build/app
  else
    cp Deezer_512x512x32.png build/app
  fi
fi

# Create Electron distribution
if ! [ -d build/dist ]; then
  electron-packager build/app app \
    --platform linux \
    --arch x64 \
    --out build/dist \
    --electron-version $ELECTRON_VERSION \
    --executable-name deezer-desktop
fi

# Include additional required icon file
if ! [ -f build/dist/app-linux-x64/resources/linux/systray.png ]; then
  mkdir -p build/dist/app-linux-x64/resources/linux
  cp build/app/Deezer_512x512x32.png \
    build/dist/app-linux-x64/resources/linux/systray.png
fi

# Create Debian package
electron-installer-redhat \
  --src build/dist/app-linux-x64 \
  --dest out \
  --arch amd64 \
  --options.productName Deezer \
  --options.icon build/dist/app-linux-x64/resources/app/Deezer_512x512x32.png \
  --options.desktopTemplate "$PWD/desktop.ejs"
