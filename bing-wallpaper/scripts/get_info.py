#!/usr/bin/env python3
"""
获取 Bing 每日壁纸信息
用法: python get_info.py [--idx N]
  --idx N  : 天数偏移量，0=当天（默认），1=昨天，2=前天...最多约15天
"""
import argparse
import json
import sys
import urllib.request

API_URL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx={idx}&n=1&mkt=zh-CN"
API_TIMEOUT = 15


def fetch_wallpaper_info(idx: int = 0) -> dict:
    """从 Bing API 获取壁纸信息，返回 dict"""
    url = API_URL.format(idx=idx)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=API_TIMEOUT) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        print(f"Error: Failed to fetch data from Bing API - {e}", file=sys.stderr)
        sys.exit(1)

    if not data.get("images"):
        print("Error: No image data returned from Bing API", file=sys.stderr)
        sys.exit(1)

    image = data["images"][0]
    return {
        "title": image.get("title", ""),
        "copyright": image.get("copyright", ""),
        "url": "https://www.bing.com" + image.get("url", ""),
        "date": image.get("startdate", ""),
    }


def main():
    parser = argparse.ArgumentParser(description="获取 Bing 每日壁纸信息")
    parser.add_argument("--idx", type=int, default=0, help="天数偏移量 (0=当天, 1=昨天, ...)")
    args = parser.parse_args()

    info = fetch_wallpaper_info(args.idx)

    print(f"Title: {info['title']}")
    print(f"Copyright: {info['copyright']}")
    print(f"URL: {info['url']}")
    print(f"Date: {info['date']}")


if __name__ == "__main__":
    main()
