# 格式化時間單位
function FormatTimes {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$false)]
        [double] $Time=0,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory=$false)]
        [double] $Digit=3
    )
    # 設定單位
    $Unit_Type = 'ms'
    # 開始換算
    if (([Math]::Floor($Time)|Measure-Object -Character).Characters -gt 3) {
        $Time = $Time/1000.0; $Unit_Type = 's'
    } if (([Math]::Floor($Time)|Measure-Object -Character).Characters -gt 3) {
        $Time = $Time/60.0; $Unit_Type = 'm'
    } if (([Math]::Floor($Time)|Measure-Object -Character).Characters -gt 3) {
        $Time = $Time/60.0; $Unit_Type = 'hr'
    } if (([Math]::Floor($Time)|Measure-Object -Character).Characters -gt 3) {
        $Time = $Time/24.0; $Unit_Type = 'day'
    } if (([Math]::Floor($Time)|Measure-Object -Character).Characters -gt 3) {
        $Time = $Time/30.0; $Unit_Type = 'month'
    } $Time = [Math]::Round($Time, $Digit)
    return "$Time$Unit_Type"
} # FormatTimes

function cmpCopy {
    param (
        [string] $Path,
        [string] $Destination,
        # [string] $TempPath,
        # [switch] $7z,
        [switch] $Log,
        [switch] $NormalCopy
    )
    # 驗證
    if (!(Test-Path -PathType:Container $Path)) { Write-Host "[錯誤]:: Path路徑輸入錯誤" -ForegroundColor:Yellow ;return }
    # 設置
    if (!$TempPath) {
        $TempPath = "$env:TEMP\cmpCopy"
        if (!(Test-Path -PathType:Container $TempPath)) { (mkdir $TempPath -Force)|Out-Null }
    }
    $zip     = 'Copy-Temp.zip'
    $zipPath = $env:TEMP
    $zipFullName = "$zipPath\$zip"
    # 建立資料夾
 
    # 複製檔案
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    if ($NormalCopy) {
        Copy-Item $Path $Destination -Recurse -Force
    } else {
        if (!(Test-Path -PathType:Leaf $zipFullName)) { $forceCompress = $false } else { $forceCompress = $true }
        Compress-Archive -CompressionLevel:Fastest $Path $zipFullName -Force:$forceCompress
        [double] $cmpTime = $stopwatch.ElapsedMilliseconds
        Expand-Archive $zipFullName $Destination -Force
    }
    [double] $time = $stopwatch.ElapsedMilliseconds

    # 輸出紀錄
    Write-Host "所有檔案已經複製完畢"
    Write-Host "  來源: " -NoNewline
    Write-Host $Path -ForegroundColor:Yellow
    Write-Host "  目標: " -NoNewline
    Write-Host $Destination -ForegroundColor:Yellow
    
    if ($Log) {
        if ($NormalCopy) {
            Write-Host "    常規複製:: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } else {
            Write-Host "    壓解複製:: " -NoNewline
            Write-Host (FormatTimes $time) -NoNewline -ForegroundColor:Yellow
            Write-Host " (壓縮: " -NoNewline
            Write-Host (FormatTimes $cmpTime) -NoNewline
            Write-Host " , 解壓: " -NoNewline
            Write-Host (FormatTimes ($time-$cmpTime)) -NoNewline
            Write-Host ")"
        }
    }
}

# 測試複製時間函式
function __TestCopyTime__ {
    $srcPath = 'autoFixEFI'
    # $srcPath = 'R:\SampleFile'
    
    $ramPath = 'R:\TestCopyTime'
    $ssdPath = "$env:temp\TestCopyTime"
    $hddPath = "E:\TestCopyTime"
    $nasPath = '\\CHARLOTTE-LT\public\TestCopyTime'

    if ($ramPath) {
        Write-Host '========================== Test Ram2Ram ==========================' -ForegroundColor:Cyan
        cmpCopy $srcPath $ramPath -Log
        cmpCopy $srcPath $ramPath -Log -NormalCopy
    }
    if ($ssdPath) {
        Write-Host '========================== Test Ram2SSD ==========================' -ForegroundColor:Cyan
        cmpCopy $srcPath $ssdPath -Log
        cmpCopy $srcPath $ssdPath -Log -NormalCopy
    }
    if ($hddPath) {
        Write-Host '========================== Test Ram2HDD ==========================' -ForegroundColor:Cyan
        cmpCopy $srcPath $hddPath -Log
        cmpCopy $srcPath $hddPath -Log -NormalCopy
    }
    if ($nasPath) {
        Write-Host '========================== Test Ram2NAS ==========================' -ForegroundColor:Cyan
        cmpCopy $srcPath $nasPath -Log
        cmpCopy $srcPath $nasPath -Log -NormalCopy
    }
    Write-Host ""
} # __TestCopyTime__

