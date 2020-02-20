# Deezer RPM Builder

Build Deezer packages for Opensuse/Fedora, using resources extracted from Deezer's Windows or macOS packages.

## Prebuilt packages

See [Releases](TODO)

## Requirements

1. Install Node.js, e.g. using NVM:

   ```sh
   nvm install node
   ```

2. Install `asar`, `electron-packager` and `electron-installer-redhat`:

   ```sh
   npm install asar electron-packager electron-installer-redhat
   ```

2.1. Add `node_modules` to path
   ```sh
   export PATH="$PATH:$(npm bin)"
   ```

3. Install packages required for `7z`, `icns2png`, `fakeroot` and `rpm`.

   Using OpenSUSE

   ```sh
   sudo zypper in p7zip-full icns-utils fakeroot rpm-build
   ```

   Or, using macOS:

   ```sh
   brew install p7zip libicns fakeroot dpkg
   ```

4. Download the latest Deezer Windows or macOS installer, as `deezer.exe` or `deezer.dmg` respectively, e.g. using wget:

   ```sh
   wget 'https://e-cdn-content.dzcdn.net/builds/deezer-desktop/8cF2rAuKxLcU1oMDmCYm8Uiqe19Ql0HTySLssdzLkQ9ZWHuDTp2JBtQOvdrFzWPA/darwin/x64/4.18.30/DeezerDesktop_4.18.30.dmg' -O deezer.dmg
   ```

# Build

Run the build script:

```sh
./build.sh <platform>
```

replacing `<platform>` with either `windows` or `mac`, depending on which sources you would like to build from.

Once complete, you should have a RPM package in the `out` directory.
