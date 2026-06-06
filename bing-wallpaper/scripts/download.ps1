param([int]$Idx = 0)

$response = Invoke-RestMethod -Uri "https://www.bing.com/HPImageArchive.aspx?format=js&idx=$Idx&n=1&mkt=zh-CN"
$imageInfo = $response.images[0]
$imageUrl = 'https://www.bing.com' + $imageInfo.url

$dateStr = Get-Date -Format 'yyyyMMdd_HHmmss'

# 跨平台桌面路径检测
if ($env:OS -eq 'Windows_NT' -or $IsWindows) {
    $desktopPath = [Environment]::GetFolderPath('Desktop')
} else {
    $desktopPath = Join-Path $HOME 'Desktop'
    if (-not (Test-Path $desktopPath)) {
        $desktopPath = $HOME
    }
}

$savePath = Join-Path $desktopPath ('BingWallpaper_' + $dateStr + '.jpg')

Invoke-WebRequest -Uri $imageUrl -OutFile $savePath -TimeoutSec 30

Write-Output ('Saved: ' + $savePath)
Write-Output ('Title: ' + $imageInfo.title)
Write-Output ('Copyright: ' + $imageInfo.copyright)
Write-Output ('Date: ' + $imageInfo.startdate)
