#!/bin/sh
# Runs VRCX from /config/VRCX.AppImage and keeps it running.
# First start downloads the latest release. After that VRCX's built-in updater
# replaces the AppImage, and the watcher below restarts VRCX onto it.
set -u

APP=/config/VRCX.AppImage
RUN_DIR=/tmp/vrcx
PROC_RE='(/tmp/vrcx/squashfs-root|appimage_extracted_[^/]*)/VRCX'

export HOME=/config
export USER="${USER:-app}"
export XDG_CONFIG_HOME=/config/xdg/config
export XDG_CACHE_HOME=/config/xdg/cache
export XDG_DATA_HOME=/config/xdg/data
# Tells VRCX's updater which file to replace; the other two let VRCX
# relaunch itself through the AppImage without FUSE.
export APPIMAGE="$APP"
export APPIMAGE_EXTRACT_AND_RUN=1
export NO_CLEANUP=1
cd /config

case "$(uname -m)" in
    x86_64)  ARCH=x64 ;;
    aarch64) ARCH=arm64 ;;
    *) echo "Unsupported CPU: $(uname -m)"; exit 1 ;;
esac

install_latest() {
    echo "Downloading latest VRCX ($ARCH) ..."
    url=$(curl -fsSL https://api.github.com/repos/vrcx-team/VRCX/releases/latest \
        | jq -r --arg s "${ARCH}.AppImage" '.assets[] | select(.name | endswith($s)) | .browser_download_url' \
        | head -n1)
    [ -n "$url" ] && curl -fL -o "$APP.download" "$url" && mv -f "$APP.download" "$APP"
}

signature() { stat -c '%i:%Y:%s' "$APP" 2>/dev/null; }

while true; do
    if [ ! -s "$APP" ] && ! install_latest; then
        echo "Download failed, retrying in 60s."
        sleep 60
        continue
    fi
    chmod +x "$APP"

    rm -rf "$RUN_DIR" /tmp/appimage_extracted_*
    mkdir -p "$RUN_DIR"
    ( cd "$RUN_DIR" && "$APP" --appimage-extract >/dev/null ) || { rm -f "$APP"; continue; }

    START_SIG=$(signature)
    "$RUN_DIR/squashfs-root/AppRun" --no-sandbox --disable-gpu --disable-dev-shm-usage \
        --no-install --no-desktop --config=/config/VRCX &
    APP_PID=$!

    # Restart onto a new version once VRCX's updater has downloaded it.
    (
        while sleep 300; do
            if [ "$(signature)" != "$START_SIG" ] && [ -x "$APP" ]; then
                echo "New VRCX version downloaded, restarting."
                pkill -TERM -f "$PROC_RE"
                break
            fi
        done
    ) &
    WATCH_PID=$!

    wait "$APP_PID"
    # VRCX's own "Restart" relaunches it; wait until no copy is running.
    while pgrep -f "$PROC_RE" >/dev/null; do sleep 5; done
    kill "$WATCH_PID" 2>/dev/null

    echo "VRCX exited, restarting in 5s."
    sleep 5
done
