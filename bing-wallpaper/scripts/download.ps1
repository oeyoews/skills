param([int]$Idx = 0)

$response = Invoke-RestMethod -Uri "https://www.bing.com/HPImageArchive.aspx?format=js&idx=$Idx&n=1&mkt=zh-CN"
$imageInfo = $response.images[0]
$imageUrl = 'https://www.bing.com' + $imageInfo.url

$dateStr = Get-Date -Format 'yyyyMMdd_HHmmss'

# 跨平台桌面路径：始终使用 .NET 方法获取真实桌面路径
# 支持中文路径、自定义桌面位置等
if ($IsWindows) {
    # Windows: 使用 Shell 获取真实桌面路径（支持中文、自定义位置）
    $shell = New-Object -ComObject Shell.Application
    $desktopPath = $shell.NameSpace(0x00).Self.Path
} elseif ($IsMacOS) {
    $desktopPath = Join-Path $HOME 'Desktop'
    if (-not (Test-Path $desktopPath)) {
        $desktopPath = $HOME
    }
} elseif ($IsLinux) {
    # Linux: 优先用 xdg-user-dir，回退到 ~/Desktop
    $xdgDesktop = & xdg-user-dir DESKTOP 2>$null
    if ($xdgDesktop -and (Test-Path $xdgDesktop)) {
        $desktopPath = $xdgDesktop
    } else {
        $desktopPath = Join-Path $HOME 'Desktop'
        if (-not (Test-Path $desktopPath)) {
            $desktopPath = $HOME
        }
    }
} else {
    $desktopPath = $HOME
}

$savePath = Join-Path $desktopPath ('BingWallpaper_' + $dateStr + '.jpg')

Invoke-WebRequest -Uri $imageUrl -OutFile $savePath -TimeoutSec 30

Write-Output ('Saved: ' + $savePath)
Write-Output ('Title: ' + $imageInfo.title)
Write-Output ('Copyright: ' + $imageInfo.copyright)
Write-Output ('Date: ' + $imageInfo.startdate)
