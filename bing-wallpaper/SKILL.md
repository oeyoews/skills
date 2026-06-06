---
name: bing-wallpaper
description: 从微软 Bing 获取当日壁纸并下载到本地桌面。支持 Windows、Linux、macOS 平台，自动检测平台选择 PowerShell 或 Bash 脚本执行。当用户要求下载壁纸、Bing 壁纸、每日壁纸、设置桌面背景时使用。
---

# Bing 每日壁纸下载

从微软 Bing 获取当日壁纸并下载到本地桌面。

支持 **Windows**、**Linux**、**macOS** 平台。

## 前置要求

- **Windows**：自带 PowerShell 5.x / 7，无需额外安装；可选 Git Bash（Git for Windows 附带）
- **Linux**：需要 `curl`（大多数发行版自带，否则 `apt install curl` / `yum install curl`）
- **macOS**：自带 `curl`，无需额外安装

## 脚本版本

本技能提供两套脚本，根据平台选择执行：

| 脚本 | 适用平台 | 依赖 |
|------|----------|------|
| `scripts/get_info.ps1` / `download.ps1` | Windows | PowerShell（系统自带） |
| `scripts/get_info.sh` / `download.sh` | Linux / macOS / Windows Git Bash | curl |

## 流程

### 1. 获取壁纸信息

先确定本技能安装目录的绝对路径（即 SKILL.md 所在目录），然后执行脚本：

- **Windows（PowerShell）**：
  ```powershell
  pwsh -ExecutionPolicy Bypass -File <skill_dir>\scripts\get_info.ps1 [-Idx N]
  ```
  如果 `pwsh` 不可用（仅 Windows 自带 PowerShell 5.x），用：
  ```powershell
  powershell -ExecutionPolicy Bypass -File <skill_dir>\scripts\get_info.ps1 [-Idx N]
  ```

- **Linux / macOS / Git Bash**：
  ```bash
  bash <skill_dir>/scripts/get_info.sh [Idx]
  ```

其中 `<skill_dir>` 为本技能目录的绝对路径（即 SKILL.md 所在目录）。

可选参数 `Idx` 用于获取历史壁纸（N 为天数偏移量）：
- `Idx 0`（默认）：当天壁纸
- `Idx 1`：昨天
- `Idx 2`：前天
- 以此类推，最多支持约 15 天内的历史壁纸

从脚本输出中提取以下信息展示给用户：
- **标题**：`Title:` 后的内容
- **描述/版权**：`Copyright:` 后的内容
- **图片 URL**：`URL:` 后的内容
- **壁纸日期**：`Date:` 后的内容

### 2. 下载壁纸

- **Windows（PowerShell）**：
  ```powershell
  pwsh -ExecutionPolicy Bypass -File <skill_dir>\scripts\download.ps1 [-Idx N]
  ```
  或（Windows 自带 PowerShell 5.x）：
  ```powershell
  powershell -ExecutionPolicy Bypass -File <skill_dir>\scripts\download.ps1 [-Idx N]
  ```

- **Linux / macOS / Git Bash**：
  ```bash
  bash <skill_dir>/scripts/download.sh [Idx]
  ```

脚本会调用 Bing API 获取图片 URL，然后下载壁纸保存到桌面 `BingWallpaper_yyyyMMdd_HHmmss.jpg`（日期时间取下载时刻），无需用户指定路径。

同样支持 `Idx` 参数下载历史壁纸，用法同上。

### 3. 告知用户

壁纸保存完成后，汇总告知：
- 保存路径（完整路径）
- 图片标题
- 版权信息
- 壁纸日期

## 跨平台桌面路径

脚本自动通过系统 API 获取**真实桌面路径**，支持中文路径和用户自定义桌面位置：

| 平台 | 桌面路径获取方式 | 说明 |
|------|-----------------|------|
| Windows (PowerShell) | `Shell.Application.NameSpace(0x0a).Self.Path` | 读取 Shell 桌面路径，支持中文及自定义位置 |
| Windows (Git Bash) | `[Environment]::GetFolderPath('Desktop')` | 通过 PowerShell 获取真实桌面路径 |
| Linux | `$XDG_DESKTOP_DIR` → `xdg-user-dir DESKTOP` → `~/Desktop/` → `~/` | 优先 XDG 环境变量，逐级回退 |
| macOS | `~/Desktop/` → `~/` | 桌面不存在时回退到主目录 |

## 注意事项

- **必须**通过 `-ExecutionPolicy Bypass` 执行 PowerShell 脚本，否则默认策略会阻止运行
- PowerShell 脚本使用 `-File` 参数，路径和参数均由 PowerShell 原生解析，无需引号包裹或转义
- Bash 脚本使用 `curl + grep + sed` 实现，不依赖 PowerShell
- API 请求超时 15 秒（Bash）/ 默认超时（PowerShell），下载超时 30 秒
- 壁纸默认保存为 JPG 格式，文件名为 `BingWallpaper_下载日期时间.jpg`
- 历史壁纸最多支持约 15 天，超出范围可能返回空数据
