param([int]$Idx = 0)

$response = Invoke-RestMethod -Uri "https://www.bing.com/HPImageArchive.aspx?format=js&idx=$Idx&n=1&mkt=zh-CN"
$imageInfo = $response.images[0]

Write-Output ('Title: ' + $imageInfo.title)
Write-Output ('Copyright: ' + $imageInfo.copyright)
Write-Output ('URL: https://www.bing.com' + $imageInfo.url)
Write-Output ('Date: ' + $imageInfo.startdate)
