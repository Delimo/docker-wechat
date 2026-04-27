FROM jlesage/baseimage-gui:ubuntu-20.04-v4

ARG TARGETPLATFORM
ENV DEBIAN_FRONTEND=noninteractive

# 1. 设置应用名称和环境 (解决 Error 127 问题)
ENV APP_NAME="微信" \
    LC_ALL=zh_CN.UTF-8 \
    LANG=zh_CN.UTF-8 \
    XMODIFIERS="@im=fcitx" \
    GTK_IM_MODULE="fcitx" \
    QT_IM_MODULE="fcitx" \
    XIM_PROGRAM="fcitx" \
    XIM=fcitx

# 2. 基础系统优化，开启 universe 源并安装核心依赖
RUN sed -i 's/main/main universe/' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg locales fonts-noto-cjk language-pack-zh-hans \
    lsb-release xdg-utils libnss3 libasound2 \
    # Fcitx Rime 核心包 (修正包名为 librime-data-luna-pinyin)
    fcitx-bin fcitx-rime fcitx-module-dbus fcitx-frontend-gtk2 fcitx-frontend-gtk3 fcitx-frontend-qt5 \
    librime-data-luna-pinyin im-config && \
    locale-gen zh_CN.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 3. 预配置 Rime (简体中文方案)
RUN mkdir -p /config/xdg/config/fcitx/rime && \
    echo -e "[Profile]\nIMList=fcitx-keyboard-us:True,rime:True\nDefaultIM=rime" > /config/xdg/config/fcitx/profile && \
    echo -e "patch:\n  schema_list:\n    - schema: luna_pinyin_simp" > /config/xdg/config/fcitx/rime/default.custom.yaml

# 4. 下载并安装微信
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"; \
    fi && \
    curl -L -o /tmp/wechat.deb "$WECHAT_URL" && \
    (dpkg -i /tmp/wechat.deb || (apt-get update && apt-get install -fy)) && \
    rm /tmp/wechat.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 5. 启动脚本配置
COPY startapp-enhanced.sh /startapp-enhanced.sh
RUN chmod +x /startapp-enhanced.sh
RUN echo '#!/bin/sh\nexec /startapp-enhanced.sh' > /startapp.sh && chmod +x /startapp.sh

VOLUME /root/.xwechat /root/xwechat_files /root/downloads
