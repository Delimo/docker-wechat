#!/bin/bash

# 环境变量
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XIM_PROGRAM="fcitx"
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

# 初始化 D-Bus
if [ ! -d "/run/user/0" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:abstract=/tmp/dbus-session-$$"
    dbus-daemon --session --fork --address="$DBUS_SESSION_BUS_ADDRESS"
fi

# 启动 Fcitx
start_fcitx() {
    pkill -9 fcitx 2>/dev/null
    rm -rf /tmp/fcitx-*
    fcitx -d
    # 等待输入法启动并强制设为 Rime
    sleep 5
    fcitx-remote -s rime 2>/dev/null
}

# 简单的健康检查：每30秒检查一次 fcitx 进程
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
