using module ".\module\smart.psm1"
using module ".\module\html.psm1"
using module ".\module\mail.psm1"


function makeDirectory([object] $logger, [string] $dir){
    [bool] $testPath = Test-Path $dir
    if(!$testPath){
        New-Item $dir -ItemType Directory
    }

    [string] $absolutePath = Convert-Path $dir
    if(!$testPath){
        $logger.Logging("info", "mkdir [${absolutePath}].")
    }else{
        $logger.Logging("info", "[${absolutePath}] is already exists.")
    }
    # 絶対パスを返す
    return $absolutePath
}


function stopProcess([string] $processName){
    try {
        Stop-Process -Name $processName
        return @{ "done" = $true }
    }
    catch {
        return @{
            "done" = $false
            "message" = $PSItem.Exception.Message
        }
    }
}


function fileExists([object] $logger, [hashtable] $pathes){
    [bool] $exists = $false
    foreach($key in $pathes.Keys){
        if(Test-Path $pathes[$key]){
            $logger.Logging("info", "Exists [{0}]" -f $pathes[$key])
            $exists = $true
        }else{
            $logger.Logging("error", "NOT exists [{0}]" -f $pathes[$key])
            $exists = $false
        }
    }
    return $exists
}


function main([string] $configFilePath, [object] $logger) {
    # 設定ファイル読み込み
    $logger.Logging("info", "Load config file [{0}]." -f $configFilePath)
    [hashtable] $config = (Get-Content $configFilePath | ConvertFrom-Json -AsHashtable)

    # 多重起動できないようなので、すでに走っているDiskInfoプロセスをkillする
    [string] $processName = $config.CDI_EXE_FILE.Replace(".exe", "")
    [hashtable] $processStopped = stopProcess $processName
    if($processStopped.done){
        $logger.Logging("info", "[{0}] process stopped." -f $processName)
    }else{
        $logger.Logging("error", "{0}." -f $processStopped.message)
    }

    # CDIのコマンドラインオプションでSMARTをDiskInfo.txt に出力
    # https://crystalmark.info/ja/software/crystaldiskinfo/crystaldiskinfo-advanced-features/
    Set-Variable -name CDI_EXE_FILE_PATH -value ("{0}\{1}" -f $config.CDI_DIRECTORY, $config.CDI_EXE_FILE) -option constant
    $logger.Logging("info", ("Start Process: [{0} {1}]" -f $CDI_EXE_FILE_PATH, $config.CDI_OPTION))
    Start-Process -FilePath $CDI_EXE_FILE_PATH -Wait -ArgumentList $config.CDI_OPTION

    # 出力・コピーしてくるSMART情報テキストファイル名
    Set-Variable -name CDI_SMART_FILE_NAME -value "DiskInfo.txt" -option constant
    # ex) C:\Program Files\CrystalDiskInfo\DiskInfo.txt
    [string] $cdiSmartFilePath = "{0}\{1}" -f $config.CDI_DIRECTORY, $CDI_SMART_FILE_NAME
    # コピー先ディレクトリがなかったら作成
    [string] $copyDestinationDirectory = makeDirectory $logger ".\data"
    # dataディレクトリにコピー
    if(Test-Path $cdiSmartFilePath){
        $logger.Logging("info", ("Copy [{0}] to [{1}]." -f $cdiSmartFilePath, $copyDestinationDirectory))
        Copy-Item -Path $cdiSmartFilePath -Destination $copyDestinationDirectory -Force
    }else{
        $logger.Logging("error", ("[{0}] is NOT exists." -f $cdiSmartFilePath))
        return
    }

    # コピーしたSMARTファイルを読み込み
    [string] $copiedCdiSmartFilePath = "{0}\{1}" -f $copyDestinationDirectory, $CDI_SMART_FILE_NAME
    if(Test-Path $copiedCdiSmartFilePath){
        $logger.Logging("info", ("Load [{0}]." -f $copiedCdiSmartFilePath))
    }else{
        $logger.Logging("error", ("[{0}] is NOT exists." -f $copiedCdiSmartFilePath))
        return
    }

    # SMART情報取得
    [object] $smart = [Smart]::new($copiedCdiSmartFilePath)
    [object] $smartInfo = $smart.extractSmart()
    # jsonファイルに書き出し
    [string] $now = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
    [string] $smartOutputDirectory = makeDirectory $logger ".\data\smart"
    [string] $smartJsonPath = "${smartOutputDirectory}/${now}.json"
    $smartInfo | ConvertTo-Json -Depth 5 | Out-File $smartJsonPath -Encoding utf8

    if(Test-Path $smartJsonPath){
        $logger.Logging("info", ("Success: Output SMART to [{0}]." -f $smartJsonPath))
    }else{
        $logger.Logging("error", ("Failed: Output SMART to [{0}]." -f $smartJsonPath))
        return
    }

    # HTML作成
    [string] $baseHtmlPath = Convert-Path ".\app\template\base.html"
    [object] $html = [Html]::new($baseHtmlPath)
    [string] $htmlContent = $html.BuildHtmlContent($smartInfo)

    [string] $htmlOutputDirectory = makeDirectory $logger "D:\NAS\html"
    [string] $htmlOutFilePath = "${htmlOutputDirectory}\smart.html"
    $htmlContent | Out-File $htmlOutFilePath -Encoding utf8

    if(Test-Path $htmlOutFilePath){
        $logger.Logging("info", ("Success: Output HTML to [{0}]." -f $htmlOutFilePath))
    }else{
        $logger.Logging("error", ("Failed: Output HTML to [{0}]." -f $htmlOutFilePath))
    }

    # メール用ライブラリ読み込み
    [string] $mailLibraries = (@($config.MAIL_LIBRARIES.Keys) -join ", ")
    $logger.Logging("info", ("Load mail libraries [{0}]." -f $mailLibraries))
    [bool] $mailLibrariesExists = fileExists $logger $config.MAIL_LIBRARIES

    # メール用ライブラリあったらメール送信実行
    if($mailLibrariesExists){
        $logger.Logging("info", ("Start to send email."))
        [object] $mail = [Mail]::new($config.MAIL, $config.MAIL_LIBRARIES)
        [hashtable] $mailResult = $mail.SendMail($htmlContent)

        # メール送信結果
        if($mailResult.done){
            $logger.Logging("info", "Message sent successfully.")
        }else{
            $logger.Logging("error", $mailResult.message)
        }
    }else{
        # メール用ライブラリがなかったらアプリケーション終了
        return
    }
}
