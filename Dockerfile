FROM jlesage/baseimage-gui:ubuntu-20.04-v4

ARG TARGETARCH

RUN sed -i 's@/archive.ubuntu.com/@/mirrors.aliyun.com/@g' /etc/apt/sources.list && \
    apt update && \
    apt install -y locales language-pack-zh-hans fonts-noto-cjk-extra curl wget \
    fcitx fcitx-rime librime-data-pinyin-simp dbus-x11 libasound2 libgbm1 \
    libnss3 libatk1.0-0 libatk-bridge2.0-0 libcups2 libdrm2 \
    libgtk-3-0 libpango-1.0-0 libxshmfence1 binutils && \
    locale-gen zh_CN.UTF-8

RUN if [ "$TARGETARCH" = "amd64" ]; then \
        wget https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb -O /tmp/wechat.deb; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        wget https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb -O /tmp/wechat.deb; \
    fi && \
    apt install -y /tmp/wechat.deb && \
    rm /tmp/wechat.deb

RUN mkdir -p /config/.local/share/fcitx/rime
COPY default.custom.yaml /config/.local/share/fcitx/rime/default.custom.yaml

COPY startapp-enhanced.sh /usr/local/bin/wechat-start.sh
RUN chmod +x /usr/local/bin/wechat-start.sh && \
    echo "#!/bin/sh\nexec /usr/local/bin/wechat-start.sh" > /startapp.sh && \
    chmod +x /startapp.sh

ENV LANG=zh_CN.UTF-8 LC_ALL=zh_CN.UTF-8 APP_NAME="WeChat"
VOLUME /config
