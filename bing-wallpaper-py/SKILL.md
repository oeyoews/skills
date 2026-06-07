---
name: bing-wallpaper-py
description: 从微软 Bing 获取当日壁纸并下载到本地桌面。支持 Windows、Linux、macOS 平台，使用纯 Python 3 标准库实现，无需额外依赖。当用户要求下载壁纸、Bing 壁纸、每日壁纸、设置桌面背景时使用。
---

# Bing 每日壁纸下载 (Python 版)

从微软 Bing 获取当日壁纸并下载到本地桌面。

支持 **Windows**、**Linux**、**macOS** 平台，使用纯 Python 3 实现，**无需额外安装任何依赖**（仅使用标准库）。

## 前置要求

- **Python 3.6+**（几乎所有现代操作系统都自带）
- 无需 pip install 任何第三方包，脚本仅使用 Python 标准库：
  - `urllib.request` — HTTP 请求与下载
  - `json` — JSON 解析
  - `argparse` — 命令行参数解析
  - `platform` / `os` / `sys` — 平台检测与路径操作
  - `winreg` — Windows 注册表读取（仅 Windows，标准库）
  - `subprocess` — 调用 xdg-user-dir（仅 Linux，标准库）

## 脚本版本

本技能使用 Python 脚本，跨平台统一：

| 脚本 | 功能 | 依赖 |
|------|------|------|
| `scripts/get_info.py` | 获取壁纸信息（标题、版权、URL、日期） | Python 3 标准库 |
| `scripts/download.py` | 下载壁纸到桌面 | Python 3 标准库 |

## 流程

### 1. 获取壁纸信息

```bash
python <skill_dir>/scripts/get_info.py [--idx N]
```

可选参数 `--idx` 用于获取历史壁纸（N 为天数偏移量）：
- `--idx 0`（默认）：当天壁纸
- `--idx 1`：昨天
- `--idx 2`：前天
- 以此类推，最多支持约 15 天内的历史壁纸

从脚本输出中提取以下信息展示给用户：
- **标题**：`Title:` 后的内容
- **描述/版权**：`Copyright:` 后的内容
- **图片 URL**：`URL:` 后的内容
- **壁纸日期**：`Date:` 后的内容

### 2. 预览壁纸

**在下载之前，必须先向用户展示壁纸预览。** 使用 Markdown 图片语法将壁纸直接显示在对话中：

```markdown
![壁纸标题](https://www.bing.com/th?id=...)
```

其中图片 URL 使用脚本输出中 `URL:` 后的完整地址。Bing 的壁纸 URL 本身就是公开可访问的 HTTP(S) 链接，可以直接用于预览。

展示预览后，告知用户壁纸的标题、版权信息和日期，然后询问用户是否需要下载。

### 3. 下载壁纸

用户确认需要下载后再执行下载脚本：

```bash
python <skill_dir>/scripts/download.py [--idx N]
```

脚本会调用 Bing API 获取图片 URL，然后下载壁纸保存到桌面 `BingWallpaper_yyyyMMdd_HHmmss.jpg`（日期时间取下载时刻），无需用户指定路径。

同样支持 `--idx` 参数下载历史壁纸，用法同上。

### 4. 告知用户

壁纸保存完成后，汇总告知：
- 保存路径（完整路径）
- 图片标题
- 版权信息
- 壁纸日期

## 跨平台桌面路径

脚本自动通过系统 API 获取**真实桌面路径**，支持中文路径和用户自定义桌面位置：

| 平台 | 桌面路径获取方式 | 说明 |
|------|-----------------|------|
| Windows | 读取注册表 `HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders\Desktop` | 支持中文及自定义位置，回退到 `%USERPROFILE%\Desktop` |
| Linux | `$XDG_DESKTOP_DIR` → `xdg-user-dir DESKTOP` → `~/Desktop/` → `~/` | 优先 XDG 环境变量，逐级回退 |
| macOS | `~/Desktop/` → `~/` | 桌面不存在时回退到主目录 |

## 注意事项

- 脚本使用纯 Python 3 标准库，**零外部依赖**，无需 pip install
- API 请求超时 15 秒，下载超时 30 秒
- Windows 桌面路径通过注册表读取，支持中文路径和用户自定义桌面位置
- 壁纸默认保存为 JPG 格式，文件名为 `BingWallpaper_下载日期时间.jpg`
- 历史壁纸最多支持约 15 天，超出范围可能返回空数据
- 预览功能利用了 Bing 壁纸 URL 公开可访问的特性，无需额外认证
- 脚本使用 `--idx` 参数（argparse），比原版的位置参数更规范
