#!/bin/bash

# 强制使用 X11 后端以兼容现代宿主机
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

# 确保 D-Bus 运行环境 (支持容器 root 环境)
if [ ! -d "/run/user/0" ]; then
    mkdir -p /run/user/0
    chmod 700 /run/user/0
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/0/bus"
    dbus-daemon --session --fork --address="$DBUS_SESSION_BUS_ADDRESS"
fi

# 启动并配置 Fcitx Rime
start_fcitx() {
    pkill -9 fcitx 2>/dev/null
    rm -rf /tmp/fcitx-*
    fcitx -r -d 2>/dev/null
    # 等待输入法就绪并切换
    sleep 5
    fcitx-remote -s rime 2>/dev/null
}

# 后台监控进程 (每30秒检查一次)
(
    while true; do
        if ! pgrep -x "fcitx" > /dev/null; then
            start_fcitx
        fi
        sleep 30
    done
) &

# 首次运行并启动微信
start_fcitx
exec /usr/bin/wechat
