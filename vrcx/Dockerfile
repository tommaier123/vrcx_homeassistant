ARG BUILD_FROM=jlesage/baseimage-gui:debian-12-v4
FROM ${BUILD_FROM}

# Runtime libraries for the VRCX Electron AppImage (+ bundled .NET runtime),
# plus fonts so friend names with emoji / CJK characters render.
RUN add-pkg \
        ca-certificates curl jq \
        libfuse2 procps gdb \
        libnss3 libgtk-3-0 libgbm1 libasound2 libxss1 libxtst6 libdrm2 \
        libxkbcommon0 libatk-bridge2.0-0 libcups2 libsecret-1-0 libnotify4 \
        libicu72 libssl3 xdg-utils \
        libx11-xcb1 libxcb-dri3-0 libxcb-glx0 libxcb-present0 libxcb-sync1 libxshmfence1 \
        libegl1 libgl1 libgles2 libdbusmenu-glib4 libpci3 \
        fonts-noto-core fonts-noto-color-emoji fonts-wqy-zenhei

RUN set-cont-env APP_NAME "VRCX" && \
    set-cont-env KEEP_APP_RUNNING 1 && \
    install_app_icon.sh "https://raw.githubusercontent.com/vrcx-team/VRCX/master/images/VRCX.png"

COPY rootfs/ /
COPY startapp.sh /startapp.sh
# Plain value files must NOT be executable, option scripts must be.
RUN chmod 644 /etc/cont-env.d/APP_NAME /etc/cont-env.d/KEEP_APP_RUNNING && \
    chmod 755 /startapp.sh \
        /etc/cont-env.d/DISPLAY_WIDTH /etc/cont-env.d/DISPLAY_HEIGHT /etc/cont-env.d/DARK_MODE
