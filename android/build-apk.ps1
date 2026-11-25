# Apollo 11 AGC 安卓 APK 构建 v3（手动重打包：正斜杠路径 + 正确压缩）
$ErrorActionPreference = 'Stop'
$proj = 'G:\Apollo11AGC-Android'
$work = Join-Path $proj 'build'
$sdk = 'C:\Users\13224\AppData\Local\Android\Sdk'
$bt = Join-Path $sdk 'build-tools\36.0.0'
$aj = Join-Path $sdk 'platforms\android-34\android.jar'
$env:TEMP = Join-Path $proj 'tmp'
$env:TMP = $env:TEMP
New-Item -ItemType Directory -Path $env:TEMP -Force | Out-Null
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Path $work -Force | Out-Null
Set-Location $proj

Write-Output '--- 1. aapt2 compile ---'
& (Join-Path $bt 'aapt2.exe') compile --dir 'res' -o (Join-Path $work 'res.flata')
if ($LASTEXITCODE -ne 0) { throw 'aapt2 compile 失败' }

Write-Output '--- 2. aapt2 link ---'
$gen = Join-Path $work 'gen'
New-Item -ItemType Directory -Path $gen -Force | Out-Null
& (Join-Path $bt 'aapt2.exe') link -o (Join-Path $work 'unsigned.apk') -I $aj --manifest 'AndroidManifest.xml' -A 'assets' (Join-Path $work 'res.flata') --java $gen
if ($LASTEXITCODE -ne 0) { throw 'aapt2 link 失败' }

Write-Output '--- 3. javac ---'
$classes = Join-Path $work 'classes'
New-Item -ItemType Directory -Path $classes -Force | Out-Null
$javaFiles = @()
$javaFiles += Get-ChildItem $gen -Recurse -Filter '*.java' | ForEach-Object { $_.FullName }
$javaFiles += (Join-Path $proj 'src\com\sqdcz\apollo11agc\MainActivity.java')
& javac -encoding UTF-8 -source 11 -target 11 -cp $aj -d $classes $javaFiles
if ($LASTEXITCODE -ne 0) { throw 'javac 失败' }

Write-Output '--- 4. d8 ---'
$dex = Join-Path $work 'dex'
New-Item -ItemType Directory -Path $dex -Force | Out-Null
$classFiles = Get-ChildItem $classes -Recurse -Filter '*.class' | ForEach-Object { $_.FullName }
& (Join-Path $bt 'd8.bat') --lib $aj --release --output $dex $classFiles
if ($LASTEXITCODE -ne 0) { throw 'd8 失败' }

Write-Output '--- 5. 手动重打包（正斜杠路径 + resources.arsc 不压缩）---'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$apkPath = Join-Path $work 'unsigned.apk'
$extractDir = Join-Path $work 'apk_content'
if (Test-Path $extractDir) { Remove-Item $extractDir -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory($apkPath, $extractDir)
Copy-Item (Join-Path $dex 'classes.dex') $extractDir -Force

$zipPath = Join-Path $work 'app.zip'
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
$baseLen = $extractDir.TrimEnd('\').Length + 1
foreach ($f in Get-ChildItem $extractDir -Recurse -File) {
    $rel = $f.FullName.Substring($baseLen).Replace('\', '/')
    $isStored = ($rel -eq 'resources.arsc') -or ($rel -eq 'classes.dex')
    $level = [System.IO.Compression.CompressionLevel]::Optimal
    if ($isStored) { $level = [System.IO.Compression.CompressionLevel]::NoCompression }
    $entry = $archive.CreateEntry($rel, $level)
    $es = $entry.Open()
    $fs = [System.IO.File]::OpenRead($f.FullName)
    $fs.CopyTo($es)
    $fs.Close()
    $es.Close()
}
$archive.Dispose()
Write-Output '  重打包完成'

Write-Output '--- 6. zipalign ---'
$aligned = Join-Path $work 'aligned.apk'
& (Join-Path $bt 'zipalign.exe') -f 4 $zipPath $aligned
if ($LASTEXITCODE -ne 0) { throw 'zipalign 失败' }

Write-Output '--- 7. 签名 ---'
$ks = Join-Path $proj 'debug.keystore'
if (-not (Test-Path $ks)) {
    & keytool -genkeypair -keystore $ks -storepass android -keypass android -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname 'CN=Android Debug,O=Android,C=US' 2>&1 | Out-Null
}
$finalApk = Join-Path $proj 'Apollo11AGC.apk'
if (Test-Path $finalApk) { Remove-Item $finalApk -Force }
& (Join-Path $bt 'apksigner.bat') sign --ks $ks --ks-pass pass:android --key-pass pass:android --ks-key-alias androiddebugkey --out $finalApk $aligned
if ($LASTEXITCODE -ne 0) { throw 'apksigner 失败' }

Write-Output '--- 8. 验证 ---'
$info = Get-Item $finalApk
Write-Output ("APK: {0} ({1:N2} MB)" -f $info.Name, ($info.Length/1MB))
$zip = [System.IO.Compression.ZipFile]::OpenRead($finalApk)
$badPath = ($zip.Entries | Where-Object { $_.FullName -match '\\' }).Count
Write-Output ("反斜杠条目: {0} （必须为 0）" -f $badPath)
$arsc = $zip.Entries | Where-Object { $_.FullName -eq 'resources.arsc' }
if ($arsc) {
    $method = 'STORED(OK)'
    if ($arsc.CompressedLength -lt $arsc.Length) { $method = 'DEFLATE(问题!)' }
    Write-Output ("resources.arsc: {0}" -f $method)
}
$web = @($zip.Entries | Where-Object { $_.FullName -like 'assets/web/*' })
Write-Output ("assets/web 文件数: {0}" -f $web.Count)
foreach ($e in $web | Select-Object -First 3) { Write-Output ("  示例: [{0}]" -f $e.FullName) }
$zip.Dispose()
