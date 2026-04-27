FROM jlesage/baseimage-gui:ubuntu-20.04-v4

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ENV DEBIAN_FRONTEND=noninteractive

# 中国替换APT源逻辑（在海外编译会自动跳过）
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak && \
    sed -i 's@/archive.ubuntu.com/@/mirrors.aliyun.com/@g' /etc/apt/sources.list && \
    sed -i 's@/security.ubuntu.com/@/mirrors.aliyun.com/@g' /etc/apt/sources.list && \
    apt update && \
    apt install curl -y && \
    COUNTRY_CODE=$(curl -s --connect-timeout 3 --max-time 5 https://ifconfig.co/country-iso | tr -d '[:space:]' | awk '{print toupper($0)}') || COUNTRY_CODE=CN; \
    if [ "$COUNTRY_CODE" != "CN" ]; then \
        mv -f /etc/apt/sources.list.bak /etc/apt/sources.list && \
        apt update; \
    fi

# 安装系统依赖和字体
RUN apt install -y locales language-pack-zh-hans fonts-noto-cjk-extra curl \
    && locale-gen zh_CN.UTF-8 \
    && apt install -y shared-mime-info desktop-file-utils libxcb1 libxcb-icccm4 libxcb-image0 \
    libxcb-keysyms1 libxcb-randr0 libxcb-render0 libxcb-render-util0 libxcb-shape0 \
    libxcb-shm0 libxcb-sync1 libxcb-util1 libxcb-xfixes0 libxcb-xkb1 libxcb-xinerama0 \
    libxcb-glx0 libatk1.0-0 libatk-bridge2.0-0 libc6 libcairo2 libcups2 \
    libdbus-1-3 libfontconfig1 libgbm1 libgcc1 libgdk-pixbuf2.0-0 libglib2.0-0 \
    libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 \
    libxcomposite1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 libatomic1 libxkbcommon-x11-0 libasound2 lsb-release

# 安装 fcitx 和 Rime (中州韵)
RUN apt install -y fcitx fcitx-config-gtk fcitx-rime fcitx-frontend-all rime-data-luna-pinyin im-config && \
    apt purge -y ibus && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# 预配置 Rime：默认启用简体中文 (luna_pinyin_simp)
RUN mkdir -p /config/xdg/config/fcitx/rime && \
    echo -e "[Profile]\nIMList=fcitx-keyboard-us:True,rime:True\nDefaultIM=rime" > /config/xdg/config/fcitx/profile && \
    echo -e "patch:\n  schema_list:\n    - schema: luna_pinyin_simp" > /config/xdg/config/fcitx/rime/default.custom.yaml

# 设置微信图标
RUN APP_ICON_URL=https://res.wx.qq.com/a/wx_fed/assets/res/NTI4MWU5.ico && \
    install_app_icon.sh "$APP_ICON_URL"
    
RUN set-cont-env APP_NAME "微信"

# 多架构下载微信
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        curl -o /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        curl -o /tmp/wechat.deb "https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"; \
    fi && \
    dpkg -i /tmp/wechat.deb 2>&1 | tee /tmp/wechat_install.log && \
    rm /tmp/wechat.deb

# 环境变量设置
ENV XMODIFIERS="@im=fcitx" \
    GTK_IM_MODULE="fcitx" \
    QT_IM_MODULE="fcitx" \
    XIM_PROGRAM="fcitx" \
    XIM=fcitx

COPY startapp-enhanced.sh /startapp-enhanced.sh
RUN chmod +x /startapp-enhanced.sh

RUN echo '#!/bin/sh\nexec /startapp-enhanced.sh' > /startapp.sh && chmod +x /startapp.sh

VOLUME /root/.xwechat /root/xwechat_files /root/downloads

# 设置版本号
RUN set-cont-env APP_VERSION "$(grep -o 'Unpacking wechat ([0-9.]*)' /tmp/wechat_install.log | sed 's/Unpacking wechat (\(.*\))/\1/')"
