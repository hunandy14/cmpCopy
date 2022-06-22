壓縮複製
===
解決小檔案傳輸問題

### 壓縮複製
```ps1
irm bit.ly/3HzGYLr|iex; cmpCopy $srcPath $dstPath
```

### 顯示詳細資訊
```ps1
irm bit.ly/3HzGYLr|iex; cmpCopy -Log $srcPath $dstPath
```

### 普通複製
```ps1
irm bit.ly/3HzGYLr|iex; cmpCopy -NormalCopy -Log $srcPath $dstPath
```

### 測試結果

```ps1
function f {
irm bit.ly/3HzGYLr|iex;
$srcPath = 'R:\pwshApp'
$dstPath = 'R:\copy\TestCopyTime'
__TestCopyTimeCore__ $srcPath $dstPath "Test to $dstPath"
} f
```

![](img/Cover.png)

```ps1
$srcPath = 'R:\pwshApp'
    
$ramPath = 'R:\copy\TestCopyTime'
$ssdPath1 = "$env:temp\TestCopyTime"
$ssdPath1 = "$env:temp\TestCopyTime4"
$ssdPath2 = "D:\TestCopyTime"
$hddPath = "E:\TestCopyTime"
$nasPath = '\\CHARLOTTE-LT\public\TestCopyTime'
__TestCopyTimeCore__ $srcPath $ramPath "Test Ram->Ram"
__TestCopyTimeCore__ $srcPath $ssdPath "Test Ram->SSD(gen4)"
__TestCopyTimeCore__ $srcPath $ssdPath "Test Ram->SSD(sata)"
__TestCopyTimeCore__ $srcPath $hddPath "Test Ram->HDD"
__TestCopyTimeCore__ $srcPath $nasPath "Test Ram->NAS"
```

```ps1
function TestCopyTime {
    irm bit.ly/3HzGYLr|iex;
    $srcPath = 'I:\copyTest\pwshApp'
    $dstPath = 'C:\Users\hunan\Desktop\copy\tempDir\test'
    __TestCopyTimeCore__ $srcPath $dstPath "Test to $dstPath"
    $dstPath = '\\192.168.2.10\Download\copyTest\tempDir\test'
    __TestCopyTimeCore__ $srcPath $dstPath "Test to $dstPath"
} TestCopyTime
```
