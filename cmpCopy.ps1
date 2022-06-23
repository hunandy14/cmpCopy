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
        [Parameter(ParameterSetName = "CompCopy")]
        [switch] $CompCopy,
        [Parameter(ParameterSetName = "RoboCopy")]
        [switch] $RoboCopy,
        [Parameter(ParameterSetName = "TeraCopy")]
        [switch] $TeraCopy,
        [Parameter(ParameterSetName = "NormalCopy")]
        [switch] $NormalCopy,
        [switch] $Log
    )
    # 驗證
    if (!(Test-Path -PathType:Container $Path)) { Write-Host "[錯誤]:: Path路徑輸入錯誤" -ForegroundColor:Yellow ;return }
    $Path = [System.IO.Path]::GetFullPath($Path)
    # 確認7z環境
    $7zPATH = "${env:ProgramFiles}\7-Zip"
    if (!(Test-Path "$7zPATH\7z.exe")) {
        $cmd = "Set-ExecutionPolicy Bypass -S:Process -F; irm chocolatey.org/install.ps1|iex; choco install -y 7zip"
        Write-Host "偵測到沒有安裝7z, 複製並執行下列代碼快速安裝"
        Write-Host $cmd -ForegroundColor:Yellow
        return;
    } else { $env:Path = "${env:Path};$7zPATH" }
    # 設置
    if (!$TempPath) {
        $TempPath = "$env:TEMP\cmpCopy"
        if (!(Test-Path -PathType:Container $TempPath)) { (mkdir $TempPath -Force)|Out-Null }
    }
    $pathIdx = $Path.LastIndexOf('\')
    $zip     = $Path.Substring($pathIdx+1, ($Path.Length)-$pathIdx-1)+'.zip'
    $zipPath = $Path.Substring(0, $pathIdx)
    $zipFullName = "$zipPath\$zip"
    # 建立資料夾
    $destPath = $Destination+$Path.Substring($Path.LastIndexOf('\'), $Path.Length-$Path.LastIndexOf('\'))
    if (!(Test-Path -PathType:Container $destPath)) { (mkdir $destPath -Force)|Out-Null }
    
    # 複製檔案
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    if ($NormalCopy) {
        Copy-Item $Path $Destination -Recurse -Force
    } elseif ($RoboCopy) {
        (Robocopy.exe $Path $destPath /e /mt:16)|Out-Null
    } elseif ($TeraCopy) {
        (TeraCopy.exe copy $Path $destPath /OverwriteOlder /NoClose)|Out-Null
        # $job = Start-Job { (TeraCopy.exe copy $Path $destPath /OverwriteOlder) }
        # Wait-Job $job
        # Receive-Job $job
    } elseif($CompCopy) {
        if (!(Test-Path -PathType:Leaf $zipFullName)) { $forceCompress = $false } else { $forceCompress = $true }
        # Compress-Archive -CompressionLevel:Fastest $Path $zipFullName -Force:$forceCompress
        (7z.exe a $zipFullName $Path -mx=3)|Out-Null
        [double] $cmpTime = $stopwatch.ElapsedMilliseconds
        # Expand-Archive $zipFullName $Destination -Force
        (7z.exe x "$zipFullName" -o"$Destination" -aoa)|Out-Null
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
            Write-Host "    常規複製(Copy):: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($RoboCopy) {
            Write-Host "    多核複製(Robo):: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($TeraCopy) {
            Write-Host "    快速複製(Tera):: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($CompCopy) {
            Write-Host "    壓解複製( Zip):: " -NoNewline
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
        cmpCopy $srcPath "$destPath-0" -Log -RoboCopy
        cmpCopy $srcPath "$destPath-2" -Log -CompCopy
        cmpCopy $srcPath "$destPath-3" -Log -NormalCopy
        # cmpCopy $srcPath "$destPath-1" -Log -TeraCopy
    }
}

# 測試複製時間函式
function __TestCopyTime__ {
    param(
        
    )
    
    # addPath "C:\Program Files\TeraCopy"
    # $srcPath = 'autoFixEFI'
    # $srcPath = 'R:\autoFixEFI'
    $srcPath = 'R:\pwshApp'
    # $srcPath = 'R:\SampleFile'
    
    $ramPath = 'R:\temp\TestCopyTime'
    # $ssdPath1 = "$env:temp\TestCopyTime"
    # $ssdPath1 = "$env:temp\TestCopyTime4"
    # $ssdPath2 = "D:\TestCopyTime"
    # $hddPath = "E:\TestCopyTime"
    # $nasPath = '\\CHARLOTTE-LT\public\temp\TestCopyTime'

    __TestCopyTimeCore__ $srcPath $ramPath "Test Ram->Ram"
    __TestCopyTimeCore__ $srcPath $ssdPath1 "Test Ram->SSD(gen4)"
    __TestCopyTimeCore__ $srcPath $ssdPath2 "Test Ram->SSD(sata)"
    __TestCopyTimeCore__ $srcPath $hddPath "Test Ram->HDD"
    __TestCopyTimeCore__ $srcPath $nasPath "Test Ram->NAS"
    Write-Host "===================================================================" -ForegroundColor:Cyan
    Write-Host ""
    Write-Host ""
    Write-Host ""
} # __TestCopyTime__
