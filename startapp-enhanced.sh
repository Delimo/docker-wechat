#!/bin/bash
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XIM_PROGRAM="fcitx"
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb

# 自动处理 D-Bus 地址
if [ "$(id -u)" = "0" ] && [ ! -d "/run/user/0" ]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:abstract=/tmp/dbus-session-$$"
else
    export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}
fi

LOG_FILE="/tmp/fcitx-monitor.log"
log_message() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"; }

start_dbus() {
    if ! pgrep -x "dbus-daemon" > /dev/null; then
        dbus-daemon --session --fork --address="$DBUS_SESSION_BUS_ADDRESS"
        sleep 1
    fi
}

start_fcitx() {
    log_message "启动 Fcitx Rime..."
    pkill -f fcitx 2>/dev/null
    rm -rf /tmp/fcitx-* 2>/dev/null
    
    fcitx -d --enable=2 &
    
    # 等待就绪并切换到 Rime
    for i in {1..15}; do
        if [ "$(fcitx-remote 2>/dev/null)" = "1" ]; then
            fcitx-remote -s rime 2>/dev/null
            log_message "Rime 已就绪"
            return 0
        fi
        sleep 1
    done
    return 1
}

fcitx_monitor() {
    while true; do
        if ! fcitx-remote > /dev/null 2>&1; then
            log_message "检测到 Fcitx 异常，重启中..."
            start_fcitx
        fi
        sleep 5
    done
}

main() {
    start_dbus
    start_fcitx
    fcitx_monitor &
    # 启动微信
    exec /usr/bin/wechat
}

main "$@"
