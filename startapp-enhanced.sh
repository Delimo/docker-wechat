#!/bin/bash
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE="fcitx"
export QT_IM_MODULE="fcitx"
export XIM_PROGRAM="fcitx"
export XIM="fcitx"
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
export DISPLAY=${DISPLAY:-:0}

# 确保 D-Bus 运行
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax)
fi

# 启动 fcitx
pkill -9 fcitx 2>/dev/null || true
mkdir -p /config/.config/fcitx/socket
fcitx -d --enable=2 &

# 监控 fcitx 并启动微信
(
  sleep 5
  fcitx-remote -s rime 2>/dev/null
  while true; do
    if [ "$(fcitx-remote 2>/dev/null)" != "1" ]; then
        fcitx -d --enable=2 &
        sleep 2
        fcitx-remote -s rime 2>/dev/null
    fi
    sleep 5
  done
) &

# 官方微信安装路径
exec /opt/wechat/wechat
