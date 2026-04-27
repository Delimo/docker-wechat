#!/bin/bash

# 环境变量
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XIM_PROGRAM="fcitx"
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

# 确保 D-Bus 运行环境
if [ ! -d "/run/user/0" ]; then
    mkdir -p /run/user/0
    chmod 700 /run/user/0
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/0/bus"
    dbus-daemon --session --fork --address="$DBUS_SESSION_BUS_ADDRESS"
fi

# 启动 Fcitx
start_fcitx() {
    pkill -9 fcitx 2>/dev/null
    rm -rf /tmp/fcitx-*
    # 使用最小化启动参数
    fcitx -r -d 2>/dev/null
    sleep 3
    fcitx-remote -s rime 2>/dev/null
}

# 后台监控
(
    while true; do
        if ! pgrep -x "fcitx" > /dev/null; then
            start_fcitx
        fi
        sleep 30
    done
) &

# 运行微信
start_fcitx
exec /usr/bin/wechat
