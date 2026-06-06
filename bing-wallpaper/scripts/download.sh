#!/usr/bin/env bash
# 下载 Bing 每日壁纸到本地桌面
# 用法: bash download.sh [Idx]  默认 Idx=0（当天），Idx=1（昨天），以此类推

IDX=${1:-0}
API_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=${IDX}&n=1&mkt=zh-CN"

# 请求 API 并解析 JSON
RESPONSE=$(curl -s --max-time 15 "$API_URL")

if [ -z "$RESPONSE" ]; then
    echo "Error: Failed to fetch data from Bing API"
    exit 1
fi

# 用 grep/sed 提取字段
IMAGE_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | sed 's/^"url":"//;s/"$//')
TITLE=$(echo "$RESPONSE" | grep -o '"title":"[^"]*"' | head -1 | sed 's/^"title":"//;s/"$//')
COPYRIGHT=$(echo "$RESPONSE" | grep -o '"copyright":"[^"]*"' | head -1 | sed 's/^"copyright":"//;s/"$//')
STARTDATE=$(echo "$RESPONSE" | grep -o '"startdate":"[^"]*"' | head -1 | sed 's/^"startdate":"//;s/"$//')

FULL_URL="https://www.bing.com${IMAGE_URL}"

# 生成保存文件名（当前时间戳）
DATE_STR=$(date +%Y%m%d_%H%M%S)

# 跨平台桌面路径：使用系统命令获取真实桌面路径
# 支持中文路径、自定义桌面位置等
DESKTOP_PATH=""

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)
        # Windows (Git Bash / MSYS2 / Cygwin)
        # 通过 PowerShell 获取真实桌面路径（支持中文、自定义位置）
        DESKTOP_PATH=$(powershell -NoProfile -Command "[Environment]::GetFolderPath('Desktop')" 2>/dev/null | tr -d '\r\n')
        if [ -z "$DESKTOP_PATH" ] || [ ! -d "$DESKTOP_PATH" ]; then
            # 回退：通过 USERPROFILE 拼接
            DESKTOP_PATH="${USERPROFILE}/Desktop"
        fi
        ;;
    Darwin)
        # macOS
        DESKTOP_PATH="${HOME}/Desktop"
        [ ! -d "$DESKTOP_PATH" ] && DESKTOP_PATH="${HOME}"
        ;;
    *)
        # Linux: 优先读取 XDG 环境变量，其次 xdg-user-dir，最后回退 ~/Desktop → ~/
        if [ -n "$XDG_DESKTOP_DIR" ] && [ -d "$XDG_DESKTOP_DIR" ]; then
            DESKTOP_PATH="$XDG_DESKTOP_DIR"
        else
            DESKTOP_PATH=$(xdg-user-dir DESKTOP 2>/dev/null)
            if [ -z "$DESKTOP_PATH" ] || [ ! -d "$DESKTOP_PATH" ]; then
                DESKTOP_PATH="${HOME}/Desktop"
                [ ! -d "$DESKTOP_PATH" ] && DESKTOP_PATH="${HOME}"
            fi
        fi
        ;;
esac

SAVE_PATH="${DESKTOP_PATH}/BingWallpaper_${DATE_STR}.jpg"

# 下载壁纸
curl -s --max-time 30 -o "$SAVE_PATH" "$FULL_URL"

if [ $? -ne 0 ] || [ ! -f "$SAVE_PATH" ]; then
    echo "Error: Failed to download wallpaper"
    exit 1
fi

echo "Saved: ${SAVE_PATH}"
echo "Title: ${TITLE}"
echo "Copyright: ${COPYRIGHT}"
echo "Date: ${STARTDATE}"
