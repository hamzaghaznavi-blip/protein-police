# Fire TV Speed-Up

A script that makes an Amazon Fire TV smart TV (such as the 4-Series) or a Fire TV Stick feel faster. It runs on your
computer and changes the Fire TV over your home Wi-Fi using ADB (Android's debug tool).
It doesn't need root, it doesn't uninstall anything, and `restore` undoes every change.

## What it does

| Tweak | Why it helps |
|---|---|
| Menu animations at 0.5x speed | Menus open and switch in half the time |
| Turns off crash reporting, usage logging, metrics and the sponsored screensaver/ads | These run in the background all the time, using memory and CPU |
| Clears all app caches | Frees storage. A nearly full Fire TV slows down a lot |
| Stops background apps | Frees memory for the app you're watching |
| Shows a status report | Free storage, free memory and the apps using the most memory |

## One-time setup

> **Fire TV smart TVs** (Amazon 4-Series, Omni, and similar): wherever these steps say
> **My Fire TV**, your menu is called **Device & Software**.

1. **On the Fire TV:** Settings → My Fire TV → About → click the device name 7 times
   to unlock **Developer options**. Then go to Settings → My Fire TV → Developer options
   and turn on **ADB debugging**.
2. **Find its IP address:** Settings → My Fire TV → About → Network (for example `192.168.1.50`).
3. **On your computer:** install [Android platform-tools](https://developer.android.com/tools/releases/platform-tools)
   so the `adb` command works.
   - macOS: `brew install android-platform-tools`
   - Linux: `sudo apt install adb`
   - Windows: unzip platform-tools, add it to PATH, and run the script from Git Bash or WSL.

## Usage

```bash
./firetv-speedup.sh 192.168.1.50            # full boost (recommended first run)
./firetv-speedup.sh 192.168.1.50 clean      # clear caches + stop background apps (run weekly)
./firetv-speedup.sh 192.168.1.50 status     # storage / memory report
./firetv-speedup.sh 192.168.1.50 restore    # undo everything
```

The first time you connect, the TV shows **"Allow USB debugging?"**. Tick *Always allow*,
choose OK, and run the script again.

Restart the Fire TV after a boost (Settings → My Fire TV → Restart).

## Notes

- Newer Fire OS versions don't let you turn off some Amazon services. The script reports
  those as "blocked by Fire OS, skipped". That's expected and does no harm.
- Caches fill up again as you use apps, so run `clean` every week or two.
- Other things that help: uninstall apps you don't use, and turn off Settings →
  Preferences → Featured Content (autoplay video and audio on the home screen).
- **Fire TV smart TVs** have little storage, and it fills up quickly. If `status` shows less
  than about 1 GB free, uninstall apps you don't use. Running low on storage slows them down the most.
- Turn **ADB debugging** off again when you're done if you don't want it left on.
