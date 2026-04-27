FROM jlesage/baseimage-gui:ubuntu-20.04-v4

ARG TARGETPLATFORM
ENV DEBIAN_FRONTEND=noninteractive

# 核心系统组件安装
RUN apt-get clean && apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    locales \
    language-pack-zh-hans \
    fonts-noto-cjk-extra \
    # 输入法核心包 (去掉了可能报错的图形界面配置包)
    fcitx \
    fcitx-bin \
    fcitx-rime \
    fcitx-frontend-all \
    rime-data-luna-pinyin \
    im-config \
    # 微信运行必需的基础库
    libasound2 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libgbm1 \
    libxcomposite1 \
    libxrandr2 \
    libxtst6 \
    lsb-release \
    xdg-utils && \
    locale-gen zh_CN.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 预配置 Rime (简体中文)
RUN mkdir -p /config/xdg/config/fcitx/rime && \
    echo -e "[Profile]\nIMList=fcitx-keyboard-us:True,rime:True\nDefaultIM=rime" > /config/xdg/config/fcitx/profile && \
    echo -e "patch:\n  schema_list:\n    - schema: luna_pinyin_simp" > /config/xdg/config/fcitx/rime/default.custom.yaml

# 设置应用名称
RUN set-cont-env APP_NAME "微信"

# 下载并安装微信，使用 -fy 自动修补跨架构依赖
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
        WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_x86_64.deb"; \
    elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
        WECHAT_URL="https://dldir1v6.qq.com/weixin/Universal/Linux/WeChatLinux_arm64.deb"; \
    fi && \
    curl -L -o /tmp/wechat.deb "$WECHAT_URL" && \
    # 安装时如果缺少依赖会报错，接下一行自动补齐
    (dpkg -i /tmp/wechat.deb || apt-get update && apt-get install -fy) && \
    rm /tmp/wechat.deb

# 环境变量
ENV XMODIFIERS="@im=fcitx" \
    GTK_IM_MODULE="fcitx" \
    QT_IM_MODULE="fcitx" \
    XIM_PROGRAM="fcitx" \
    LC_ALL=zh_CN.UTF-8

COPY startapp-enhanced.sh /startapp-enhanced.sh
RUN chmod +x /startapp-enhanced.sh
RUN echo '#!/bin/sh\nexec /startapp-enhanced.sh' > /startapp.sh && chmod +x /startapp.sh

VOLUME /root/.xwechat /root/xwechat_files /root/downloads

# 动态获取安装的版本
RUN set-cont-env APP_VERSION "$(dpkg-query -W -f='${Version}' wechat)"
