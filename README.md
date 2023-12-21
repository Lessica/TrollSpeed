# TrollSpeed

Shows upload &amp; download speed below the status bar.

Tested and expected to work on all iOS versions supported by opa334’s TrollStore.

You need to enable “Developer Mode” on iOS 16 or above to use TrollSpeed or Misaka.

## How it works?

[TrollStore](https://github.com/opa334/TrollStore) + [UIDaemon](https://github.com/limneos/UIDaemon) + [NetworkSpeed13](https://github.com/lwlsw/NetworkSpeed13) + (some magic)
\=

- An TrollStore app to spawn HUD process with root privilege.
- Don’t call `waitpid` to that process. Let it go.
- A HUD app with entitlements from `assistivetouchd` to display and persist global windows.

## How to build?

- Use [theos](https://github.com/theos/theos) to compile.
  - `SPAWN_AS_ROOT=1 FINALPACKAGE=1 make package`
- You'll get a `.tipa` file in `./packages` folder.

## Caveats

- Spawn with root privileges is **required**. Otherwise, the HUD process will be killed by SpringBoard when unlocking device.
- TrollSpeed will observe its app removal and terminate its HUD.

## Notes

- Please give me feedback if you find any issues &amp; bugs, or have any suggestions.
- Give me a star 🌟 if you like this project. Thanks!

## Screenshot

![screenshot](https://user-images.githubusercontent.com/5410705/213263734-1ef1b553-88d4-41cc-856e-891ea08d185c.jpeg)
