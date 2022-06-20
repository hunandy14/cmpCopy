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
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Path,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory)]
        [string] $Destination,
        # [string] $TempPath,
        # [switch] $7z,
        [Parameter(ParameterSetName = "NormalCopy")]
        [switch] $NormalCopy,
        [Parameter(ParameterSetName = "CompCopy")]
        [switch] $CompCopy,
        [Parameter(ParameterSetName = "RoboCopy")]
        [switch] $RoboCopy,
        [switch] $Log
    )
    # 驗證
    if (!(Test-Path -PathType:Container $Path)) { Write-Host "[錯誤]:: Path路徑輸入錯誤" -ForegroundColor:Yellow ;return }
    $Path = [System.IO.Path]::GetFullPath($Path)
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
    } elseif ($RoboCopy) {
        $destPath = $Destination+$Path.Substring($Path.LastIndexOf('\'), $Path.Length-$Path.LastIndexOf('\'))
        (Robocopy.exe $Path $destPath /e /mt:128)|Out-Null
    } elseif($CompCopy) {
        if (!(Test-Path -PathType:Leaf $zipFullName)) { $forceCompress = $false } else { $forceCompress = $true }
        Compress-Archive -CompressionLevel:Fastest $Path $zipFullName -Force:$forceCompress
        [double] $cmpTime = $stopwatch.ElapsedMilliseconds
        Expand-Archive $zipFullName $Destination -Force
    }
    [double] $time = $stopwatch.ElapsedMilliseconds

    # 輸出紀錄
    # Write-Host "所有檔案已經複製完畢"
    # Write-Host "  來源: " -NoNewline
    # Write-Host $Path -ForegroundColor:Yellow
    # Write-Host "  目標: " -NoNewline
    # Write-Host $Destination -ForegroundColor:Yellow
    
    if ($Log) {
        if ($NormalCopy) {
            Write-Host "    常規複製:: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($RoboCopy) {
            Write-Host "    多核複製:: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($CompCopy) {
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



function __TestCopyTimeCore__($srcPath, $destPath, $Name) {
    if ($destPath){
        Write-Host "========================== $Name ==========================" -ForegroundColor:Cyan
        cmpCopy $srcPath $destPath -Log -RoboCopy
        cmpCopy $srcPath $destPath -Log -CompCopy
        # cmpCopy $srcPath $destPath -Log -NormalCopy
    }
}

# 測試複製時間函式
function __TestCopyTime__ {
    $srcPath = 'autoFixEFI'
    # $srcPath = 'R:\SampleFile'
    
    $ramPath = 'R:\TestCopyTime'
    # $ssdPath = "$env:temp\TestCopyTime"
    # $hddPath = "E:\TestCopyTime"
    # $nasPath = '\\CHARLOTTE-LT\public\TestCopyTime'

    __TestCopyTimeCore__ $srcPath $ramPath "Test Ram->Ram"
    __TestCopyTimeCore__ $srcPath $ssdPath "Test Ram->SSD"
    __TestCopyTimeCore__ $srcPath $hddPath "Test Ram->HSD"
    __TestCopyTimeCore__ $srcPath $nasPath "Test Ram->NAS"
    Write-Host "===================================================================" -ForegroundColor:Cyan
    Write-Host ""
    Write-Host ""
    Write-Host ""
} __TestCopyTime__

