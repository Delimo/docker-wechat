FROM jlesage/baseimage-gui:ubuntu-20.04-v4

ARG TARGETPLATFORM
ENV DEBIAN_FRONTEND=noninteractive

# 合并所有安装步骤，确保索引最新，减少层数
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    language-pack-zh-hans \
    fonts-noto-cjk-extra \
    curl \
    ca-certificates \
    shared-mime-info \
    desktop-file-utils \
    libxcb1 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render0 libxcb-render-util0 libxcb-shape0 \
    libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xkb1 libxcb-xinerama0 \
    libxcb-glx0 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 \
    libdbus-1-3 libfontconfig1 libgbm1 libgcc1 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
    libxcomposite1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 libatomic1 libxkbcommon-x11-0 libasound2 lsb-release \
    # 安装 fcitx 和 rime
    fcitx \
    fcitx-config-gtk \
    fcitx-rime \
    fcitx-frontend-all \
    rime-data-luna-pinyin \
    im-config \
    && locale-gen zh_CN.UTF-8 \
    && apt-get purge -y ibus \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 预配置 Rime：默认启用简体中文 (luna_pinyin_simp)
RUN mkdir -p /config/xdg/config/fcitx/rime && \
    echo -e "[Profile]\nIMList=fcitx-keyboard-us:True,rime:True\nDefaultIM=rime" > /config/xdg/config/fcitx/profile && \
    echo -e "patch:\n  schema_list:\n    - schema: luna_pinyin_simp" > /config/xdg/config/fcitx/rime/default.custom.yaml

# 设置微信图标
RUN APP_ICON_URL=https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico && \
    install_app_icon.sh "$APP_ICON_URL"
    
RUN set-cont-env APP_NAME "微信"

# 根据目标平台下载微信
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        curl -L -o /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        curl -L -o /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"; \
    fi && \
    dpkg -i /tmp/wechat.deb || apt-get install -fy && \
    rm /tmp/wechat.deb

# 环境变量设置
ENV XMODIFIERS="@im=fcitx" \
    GTK_IM_MODULE="fcitx" \
    QT_IM_MODULE="fcitx" \
    XIM_PROGRAM="fcitx" \
    XIM=fcitx \
    LC_ALL=zh_CN.UTF-8

COPY startapp-enhanced.sh /startapp-enhanced.sh
RUN chmod +x /startapp-enhanced.sh

RUN echo '#!/bin/sh\nexec /startapp-enhanced.sh' > /startapp.sh && chmod +x /startapp.sh

VOLUME /root/.xwechat /root/xwechat_files /root/downloads

# 设置版本号 (从 dpkg 直接获取更稳妥)
RUN set-cont-env APP_VERSION "$(dpkg-query -W -f='${Version}' wechat)"
