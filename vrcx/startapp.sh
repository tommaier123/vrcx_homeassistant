#!/bin/sh
# Starts VRCX from /config/VRCX.AppImage and keeps it running.
# - First start: downloads the latest VRCX release for this CPU (x64/arm64).
# - After that, VRCX's built-in updater (Settings > "Auto Download") checks
#   hourly and replaces the AppImage. A watcher notices the new file and
#   restarts VRCX onto it, so updates apply without manual action.
set -u

APP=/config/VRCX.AppImage
DATA=/config/VRCX
PROC_RE='appimage_extracted_[^/]*/VRCX'
CHECK_INTERVAL=300

# Environment VRCX expects (data paths are derived from HOME / XDG_*).
export HOME=/config
export USER="${USER:-app}"
export XDG_CONFIG_HOME=/config/xdg/config
export XDG_CACHE_HOME=/config/xdg/cache
export XDG_DATA_HOME=/config/xdg/data
mkdir -p "$DATA" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
cd /config

# No FUSE inside the container: let the AppImage extract itself and run.
export APPIMAGE_EXTRACT_AND_RUN=1
export NO_CLEANUP=1

case "$(uname -m)" in
    x86_64|amd64)  ARCH=x64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
esac

install_latest() {
    echo "Installing latest VRCX ($ARCH) ..."
    url=$(curl -fsSL --max-time 30 https://api.github.com/repos/vrcx-team/VRCX/releases/latest \
        | jq -r --arg s "${ARCH}.AppImage" '.assets[] | select(.name | endswith($s)) | .browser_download_url' \
        | head -n1)
    [ -n "$url" ] || return 1
    curl -fL --max-time 900 -o "$APP.download" "$url" || { rm -f "$APP.download"; return 1; }
    chmod +x "$APP.download"
    mv -f "$APP.download" "$APP"
}

signature() { stat -c '%i:%Y:%s' "$APP" 2>/dev/null; }

# Clean up leftovers from older add-on versions.
rm -rf /config/vrcx-app

while true; do
    rm -rf /tmp/appimage_extracted_*

    if [ ! -s "$APP" ] && ! install_latest; then
        echo "Download failed. Retrying in 60s."
        sleep 60
        continue
    fi
    chmod +x "$APP"

    # No VRCX is running at this point, so any lock file is stale.
    rm -f "$XDG_CACHE_HOME"/VRCX/ElectronUserData/Singleton*

    START_SIG=$(signature)

    "$APP" --no-sandbox --disable-gpu --disable-dev-shm-usage \
        --no-install --no-desktop "--config=$DATA" --enable-logging=stderr &
    APP_PID=$!

    # Watch for an update downloaded by VRCX's own updater and restart onto it.
    (
        while sleep "$CHECK_INTERVAL"; do
            sig=$(signature)
            if [ -n "$sig" ] && [ "$sig" != "$START_SIG" ] && [ -x "$APP" ]; then
                echo "New VRCX version downloaded, restarting ..."
                pkill -TERM -f "$PROC_RE"
                break
            fi
        done
    ) &
    WATCH_PID=$!

    wait "$APP_PID"
    rc=$?
    echo "VRCX process ended with exit code $rc"
    # VRCX can relaunch itself (e.g. its own "Restart" button); wait while it runs.
    while pgrep -f "$PROC_RE" >/dev/null; do sleep 5; done
    kill "$WATCH_PID" 2>/dev/null

    echo "VRCX exited, restarting in 5s ..."
    sleep 5
done
