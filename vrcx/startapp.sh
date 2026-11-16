#!/bin/sh
# Starts VRCX from /config/VRCX.AppImage.
# - First start: downloads the latest VRCX release for this CPU (x64/arm64).
# - After that, VRCX's built-in updater (Settings > "Auto Download") checks
#   hourly and replaces the AppImage. A watcher notices the new file and
#   restarts VRCX onto it, so updates apply without manual action.
set -u

APP=/config/VRCX.AppImage
PROC_RE='appimage_extracted_[^/]*/VRCX'
CHECK_INTERVAL=300

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

# Clean up leftovers from older add-on versions and previous runs.
rm -rf /config/vrcx-app /tmp/appimage_extracted_*

if [ ! -s "$APP" ]; then
    if ! install_latest; then
        echo "Download failed. Retrying in 60s."
        sleep 60
        exit 1
    fi
fi
chmod +x "$APP"

START_SIG=$(signature)

"$APP" --no-sandbox --disable-gpu --disable-dev-shm-usage --no-install --no-desktop &
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
# VRCX can relaunch itself (e.g. its own "Restart" button); stay alive while it runs.
while pgrep -f "$PROC_RE" >/dev/null; do sleep 5; done

kill "$WATCH_PID" 2>/dev/null
# Exiting lets the container restart VRCX (KEEP_APP_RUNNING=1).
exit 0
