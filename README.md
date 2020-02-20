# Deezer RPM Builder

Build Deezer packages for Opensuse/Fedora, using resources extracted from Deezer's Windows or macOS packages.

## Prebuilt packages

See [Releases](https://github.com/dac73/deezer-rpm-builder/releases)

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
   wget 'https://www.deezer.com/desktop/download?platform=win32&architecture=x86' -O deezer.exe
   ```

# Build

Run the build script:

```sh
./build.sh <platform>
```

replacing `<platform>` with either `windows` or `mac`, depending on which sources you would like to build from.

Once complete, you should have a RPM package in the `out` directory.
