#!/usr/bin/env python3
"""
下载 Bing 每日壁纸到本地桌面
用法: python download.py [--idx N]
  --idx N  : 天数偏移量，0=当天（默认），1=昨天，2=前天...最多约15天
"""
import argparse
import json
import os
import platform
import sys
import urllib.request
from datetime import datetime

API_URL = "https://www.bing.com/HPImageArchive.aspx?format=js&idx={idx}&n=1&mkt=zh-CN"
API_TIMEOUT = 15
DOWNLOAD_TIMEOUT = 30


def get_desktop_path() -> str:
    """跨平台获取真实桌面路径，支持中文及自定义位置"""
    system = platform.system()

    if system == "Windows":
        # Windows: 使用注册表获取真实桌面路径（支持中文、自定义位置）
        try:
            import winreg
            with winreg.OpenKey(
                winreg.HKEY_CURRENT_USER,
                r"Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders",
            ) as key:
                desktop, _ = winreg.QueryValueEx(key, "Desktop")
                if os.path.isdir(desktop):
                    return desktop
        except Exception:
            pass
        # 回退: USERPROFILE\Desktop
        fallback = os.path.join(os.environ.get("USERPROFILE", ""), "Desktop")
        if os.path.isdir(fallback):
            return fallback
        return os.path.expanduser("~")

    elif system == "Darwin":
        # macOS
        desktop = os.path.join(os.path.expanduser("~"), "Desktop")
        if os.path.isdir(desktop):
            return desktop
        return os.path.expanduser("~")

    else:
        # Linux: 优先 XDG，其次 xdg-user-dir，最后 ~/Desktop → ~/
        xdg_desktop = os.environ.get("XDG_DESKTOP_DIR", "")
        if xdg_desktop and os.path.isdir(xdg_desktop):
            return xdg_desktop

        try:
            import subprocess
            result = subprocess.run(
                ["xdg-user-dir", "DESKTOP"],
                capture_output=True, text=True, timeout=5
            )
            path = result.stdout.strip()
            if path and os.path.isdir(path):
                return path
        except Exception:
            pass

        fallback = os.path.join(os.path.expanduser("~"), "Desktop")
        if os.path.isdir(fallback):
            return fallback
        return os.path.expanduser("~")


def fetch_wallpaper_url(idx: int = 0) -> dict:
    """从 Bing API 获取壁纸 URL 和元信息"""
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


def download_image(url: str, save_path: str) -> None:
    """下载图片到指定路径"""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=DOWNLOAD_TIMEOUT) as resp:
            with open(save_path, "wb") as f:
                while True:
                    chunk = resp.read(8192)
                    if not chunk:
                        break
                    f.write(chunk)
    except Exception as e:
        print(f"Error: Failed to download wallpaper - {e}", file=sys.stderr)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="下载 Bing 每日壁纸到本地桌面")
    parser.add_argument("--idx", type=int, default=0, help="天数偏移量 (0=当天, 1=昨天, ...)")
    args = parser.parse_args()

    # 获取壁纸信息
    info = fetch_wallpaper_url(args.idx)

    # 生成保存路径
    date_str = datetime.now().strftime("%Y%m%d_%H%M%S")
    desktop = get_desktop_path()
    filename = f"BingWallpaper_{date_str}.jpg"
    save_path = os.path.join(desktop, filename)

    # 下载壁纸
    download_image(info["url"], save_path)

    # 输出结果
    print(f"Saved: {save_path}")
    print(f"Title: {info['title']}")
    print(f"Copyright: {info['copyright']}")
    print(f"Date: {info['date']}")


if __name__ == "__main__":
    main()
