# �榡�Ʈɶ����
function FormatTimes {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$false)]
        [double] $Time=0,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory=$false)]
        [double] $Digit=3
    )
    # �]�w���
    $Unit_Type = 'ms'
    # �}�l����
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
    # ����
    if (!(Test-Path -PathType:Container $Path)) { Write-Host "[���~]:: Path���|��J���~" -ForegroundColor:Yellow ;return }
    $Path = [System.IO.Path]::GetFullPath($Path)
    # �T�{7z����
    $rarPATH = "${env:ProgramFiles}\WinRAR"
    $7zPATH = "${env:ProgramFiles}\7-Zip"
    
    if ((Test-Path "$rarPATH\rar.exe")) {
        $env:Path = "${env:Path};$rarPATH"
        $CompType='rar'
    } elseif((Test-Path "$7zPATH\7z.exe")) {
        $env:Path = "${env:Path};$7zPATH"
        $CompType='zip'
    } else {
        $cmd = "Set-ExecutionPolicy Bypass -S:Process -F; irm chocolatey.org/install.ps1|iex; choco install -y 7zip"
        Write-Host "������S���w�˸����Y�n��, �ƻs�ð���U�C�N�X�ֳt�w��7z"
        Write-Host $cmd -ForegroundColor:Yellow
        return;
    }
    
    # �]�m
    if (!$TempPath) {
        $TempPath = "$env:TEMP\cmpCopy"
        if (!(Test-Path -PathType:Container $TempPath)) { (mkdir $TempPath -Force)|Out-Null }
    }
    # $CompType='rar'
    # $CompType='zip'
    $pathIdx = $Path.LastIndexOf('\')
    $zip     = $Path.Substring($pathIdx+1, ($Path.Length)-$pathIdx-1) + ".$CompType"
    $zipPath = $Path.Substring(0, $pathIdx)
    $zipFullName = "$zipPath\$zip"
    # �إ߸�Ƨ�
    $destPath = $Destination+$Path.Substring($Path.LastIndexOf('\'), $Path.Length-$Path.LastIndexOf('\'))
    if (!(Test-Path -PathType:Container $destPath)) { (mkdir $destPath -Force)|Out-Null }
    
    # �ƻs�ɮ�
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    if ($NormalCopy) {
        Copy-Item $Path $Destination -Recurse -Force
    } elseif ($RoboCopy) {
        (Robocopy.exe $Path $destPath /e /mt:128)|Out-Null
    } elseif ($TeraCopy) {
        (TeraCopy.exe copy $Path $destPath /OverwriteOlder /NoClose)|Out-Null
        # $job = Start-Job { (TeraCopy.exe copy $Path $destPath /OverwriteOlder) }
        # Wait-Job $job
        # Receive-Job $job
    } elseif($CompCopy) {
        if (!(Test-Path -PathType:Leaf $zipFullName)) { $forceCompress = $false } else { $forceCompress = $true }
        
        # Compress-Archive -CompressionLevel:Fastest $Path $zipFullName -Force:$forceCompress
        if ($CompType -eq 'zip') {
            (7z.exe a $zipFullName $Path -mx=0)|Out-Null
        }
        if ($CompType -eq 'rar') {
            (rar.exe a $zipFullName $Path -m0)|Out-Null
        }
            
        [double] $cmpTime = $stopwatch.ElapsedMilliseconds
        
        # Expand-Archive $zipFullName $Destination -Force
        if ($CompType -eq 'zip') {
            (7z.exe x "$zipFullName" -o"$Destination" -aoa)|Out-Null
        } if ($CompType -eq 'rar'){
            (rar.exe x $zipFullName $Destination -y)|Out-Null
        }
    }
    [double] $time = $stopwatch.ElapsedMilliseconds

    # ��X����
    # Write-Host "�Ҧ��ɮפw�g�ƻs����"
    # Write-Host "  �ӷ�: " -NoNewline
    # Write-Host $Path -ForegroundColor:Yellow
    # Write-Host "  �ؼ�: " -NoNewline
    # Write-Host $Destination -ForegroundColor:Yellow
    
    if ($Log) {
        if ($NormalCopy) {
            Write-Host "    �`�W�ƻs(Copy):: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($RoboCopy) {
            Write-Host "    �h�ֽƻs(Robo):: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($TeraCopy) {
            Write-Host "    �ֳt�ƻs(Tera):: " -NoNewline
            Write-Host (FormatTimes $time) -ForegroundColor:Yellow
        } elseif($CompCopy) {
            Write-Host "    ���ѽƻs( Zip):: " -NoNewline
            Write-Host (FormatTimes $time) -NoNewline -ForegroundColor:Yellow
            Write-Host " (���Y: " -NoNewline
            Write-Host (FormatTimes $cmpTime) -NoNewline
            Write-Host " , ����: " -NoNewline
            Write-Host (FormatTimes ($time-$cmpTime)) -NoNewline
            Write-Host ")"
        }
    }
}



function __TestCopyTimeCore__($srcPath, $destPath, $Name) {
    if ($destPath){
        Write-Host "========================== $Name ==========================" -ForegroundColor:Cyan
        cmpCopy $srcPath "$destPath-0" -Log -RoboCopy
        # cmpCopy $srcPath "$destPath-2" -Log -CompCopy
        # cmpCopy $srcPath "$destPath-3" -Log -NormalCopy
        # cmpCopy $srcPath "$destPath-1" -Log -TeraCopy
    }
}

# ���սƻs�ɶ��禡
function __TestCopyTime__ {
    param(
        
    )
    
    # addPath "C:\Program Files\TeraCopy"
    # $srcPath = 'autoFixEFI'
    # $srcPath = 'R:\autoFixEFI'
    $srcPath = 'R:\pwshApp'
    # $srcPath = 'R:\SampleFile'
    
    $ramPath = 'R:\TestCopyTime\test1'
    # $ssdPath1 = "$env:temp\TestCopyTime\test1"
    # $ssdPath2 = "D:\TestCopyTime\test1"
    # $hddPath = "E:\TestCopyTime\test1"
    # $nasPath = '\\CHARLOTTE-LT\public\TestCopyTime\temp\test3'

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
