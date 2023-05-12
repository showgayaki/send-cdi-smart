using module ".\module\smart.psm1"
using module ".\module\html.psm1"


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


function Main([string] $configFilePath, [object] $logger) {
    # 設定ファイル読み込み
    $logger.Logging("info", "Load config file [{0}]." -f $configFilePath)
    [object] $config = (Get-Content $configFilePath | ConvertFrom-Json)

    # コピー先ディレクトリがなかったら作成
    [string] $copyDestinationDirectory = makeDirectory $logger ".\data"

    # 出力・コピーしてくるSMART情報テキストファイル
    Set-Variable -name CDI_SMART_FILE_NAME -value "DiskInfo.txt" -option constant

    # CDIのコマンドラインオプションでSMARTをDiskInfo.txt に出力
    # https://crystalmark.info/ja/software/crystaldiskinfo/crystaldiskinfo-advanced-features/
    Set-Variable -name CDI_EXE_FILE_PATH -value ("{0}\{1}" -f $config.CDI_DIRECTORY, $config.CDI_EXE_FILE) -option constant
    $logger.Logging("info", ("Start Process: [{0} {1}]" -f $CDI_EXE_FILE_PATH, $config.CDI_OPTION))
    Start-Process -FilePath $CDI_EXE_FILE_PATH -Wait -ArgumentList $config.CDI_OPTION

    # 取得したSMARTファイルをコピーしてくる
    [string] $cdiSmartFilePath = "{0}\{1}" -f $config.CDI_DIRECTORY, $CDI_SMART_FILE_NAME
    # dataディレクトリにコピー
    if(Test-Path $cdiSmartFilePath){
        $logger.Logging("info", ("Copy [{0}] to [{1}]." -f $cdiSmartFilePath, $copyDestinationDirectory))
        Copy-Item -Path $cdiSmartFilePath -Destination $copyDestinationDirectory -Force
    }else{
        $logger.Logging("error", ("[{0}] is NOT exists." -f $cdiSmartFilePath))
    }

    # コピーしたSMARTファイルを読み込み
    [string] $copiedCdiSmartFilePath = "{0}\{1}" -f $copyDestinationDirectory, $CDI_SMART_FILE_NAME
    $logger.Logging("info", ("Load [{0}]." -f $copiedCdiSmartFilePath))
    # SMART情報取得
    [object] $smart = [Smart]::new($copiedCdiSmartFilePath)
    [object] $smartInfo = $smart.extractSmart()
    # jsonファイルに書き出し
    [string] $now = (Get-Date).ToString("yyyy-MM-dd_HHmmss")
    [string] $smartOutputDirectory = makeDirectory $logger ".\data\smart"
    [string] $smartJsonPath = "${smartOutputDirectory}/${now}.json"
    # [string] $smartJsonPath = "${smartOutputDirectory}/smart.json"
    $smartInfo | ConvertTo-Json -Depth 5 | Out-File $smartJsonPath -Encoding utf8

    if(Test-Path $smartJsonPath){
        $logger.Logging("info", ("Success: Output SMART to [{0}]." -f $smartJsonPath))
    }else{
        $logger.Logging("error", ("Failed: Output SMART to [{0}]." -f $smartJsonPath))
    }

    [string] $baseHtmlPath = Convert-Path ".\app\template\base.html"
    [object] $html = [Html]::new($baseHtmlPath)
    [string] $htmlContent = $html.BuildHtmlContent($smartInfo)
    $htmlContent | Out-File ".\data\html\smart.html" -Encoding utf8
}
