ARG BUILD_FROM=jlesage/baseimage-gui:debian-12-v4
FROM ${BUILD_FROM}

# Libraries needed by the VRCX Electron AppImage, plus fonts for emoji/CJK names.
RUN add-pkg \
        ca-certificates curl jq procps libfuse2 \
        libnss3 libgtk-3-0 libgbm1 libasound2 libxss1 libxtst6 libdrm2 \
        libxkbcommon0 libatk-bridge2.0-0 libcups2 libsecret-1-0 libnotify4 \
        libicu72 libssl3 xdg-utils \
        libx11-xcb1 libxcb-dri3-0 libxcb-glx0 libxcb-present0 libxcb-sync1 libxshmfence1 \
        libegl1 libgl1 libgles2 libdbusmenu-glib4 libpci3 \
        fonts-noto-core fonts-noto-color-emoji fonts-wqy-zenhei

# Default screen size (desktop browsers resize it to the window), plus page
# tweaks: hide the side panel and fill the width on phones in landscape.
RUN set-cont-env APP_NAME "VRCX" && \
    set-cont-env DISPLAY_WIDTH 1280 && \
    set-cont-env DISPLAY_HEIGHT 800
COPY ui-tweaks.html /tmp/ui-tweaks.html
RUN awk '/<\/body>/{while((getline l < "/tmp/ui-tweaks.html")>0) print l} {print}' \
        /opt/noVNC/index.html > /tmp/index.html && \
    cat /tmp/index.html > /opt/noVNC/index.html && rm /tmp/index.html /tmp/ui-tweaks.html

COPY startapp.sh /startapp.sh
RUN chmod 755 /startapp.sh
