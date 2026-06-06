#!/usr/bin/env bash
# 获取 Bing 每日壁纸信息
# 用法: bash get_info.sh [Idx]  默认 Idx=0（当天），Idx=1（昨天），以此类推

IDX=${1:-0}
API_URL="https://www.bing.com/HPImageArchive.aspx?format=js&idx=${IDX}&n=1&mkt=zh-CN"

# 请求 API 并解析 JSON
RESPONSE=$(curl -s --max-time 15 "$API_URL")

if [ -z "$RESPONSE" ]; then
    echo "Error: Failed to fetch data from Bing API"
    exit 1
fi

# 用 grep/sed 提取字段
TITLE=$(echo "$RESPONSE" | grep -o '"title":"[^"]*"' | head -1 | sed 's/^"title":"//;s/"$//')
COPYRIGHT=$(echo "$RESPONSE" | grep -o '"copyright":"[^"]*"' | head -1 | sed 's/^"copyright":"//;s/"$//')
IMAGE_URL=$(echo "$RESPONSE" | grep -o '"url":"[^"]*"' | head -1 | sed 's/^"url":"//;s/"$//')
STARTDATE=$(echo "$RESPONSE" | grep -o '"startdate":"[^"]*"' | head -1 | sed 's/^"startdate":"//;s/"$//')

echo "Title: $TITLE"
echo "Copyright: $COPYRIGHT"
echo "URL: https://www.bing.com${IMAGE_URL}"
echo "Date: $STARTDATE"
