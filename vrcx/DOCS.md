# VRCX add-on

Runs the official Linux build of [VRCX](https://github.com/vrcx-team/VRCX) 
and shows it in a Home Assistant sidebar tab.

## How it works

- On first start the add-on downloads the newest VRCX release for your CPU 
  x64 or ARM64).
- After that, VRCX's built-in updater checks for new versions every hour and
  downloads them. The add-on spots the new version and restarts VRCX onto it
  within a few minutes. Keep **Settings → Auto Update** set to
  **Auto Download** in VRCX (the default).
- VRCX's data (login, friend history database) lives in the add-on's config
  folder, so it survives restarts and updates and is included in HA backups.
- If VRCX crashes or you close its window, it is restarted automatically.

## First start

1. Start the add-on and wait 1–2 minutes (the first download is ~150 MB).
   Progress shows in the **Log** tab.
2. Open **VRCX** in the sidebar and log in with your VRChat account (+ 2FA).

## Options

- `display_width` / `display_height`: size of the virtual screen.
  1280×800 works well on phones in landscape. Use something like 900×1400
  for portrait.
- `dark_mode`: dark theme for window frames and dialogs.
