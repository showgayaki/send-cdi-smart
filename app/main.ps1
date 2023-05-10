using module "./module/smart.psm1"


function Main([string] $configFilePath, [object] $logger) {
    # 設定ファイル読み込み
    $logger.Logging("info", "Load config file [{0}]." -f $configFilePath)
    [object] $config = (Get-Content $configFilePath | ConvertFrom-Json)

    # コピー先ディレクトリがなかったら作成
    Set-Variable -name DATA_DIR -value "./data" -option constant
    if(!(Test-Path $DATA_DIR)){
        New-Item $DATA_DIR -ItemType Directory
        $logger.Logging("info", "mkdir [{0}]." -f $DATA_DIR)
    }
    # コピー先のディレクトリ(Convert-Path：絶対パスに変換)
    [string] $copyDestinationDirectory = Convert-Path $DATA_DIR

    # CDIのコマンドラインオプションでSMARTをDiskInfo.txt に出力
    # https://crystalmark.info/ja/software/crystaldiskinfo/crystaldiskinfo-advanced-features/
    Set-Variable -name CDI_EXE_FILE_PATH -value ("{0}\{1}" -f $config.CDI_DIRECTORY, $config.CDI_EXE_FILE) -option constant
    Start-Process -FilePath $CDI_EXE_FILE_PATH -Wait -ArgumentList $config.CDI_OPTION

    # 取得したSMARTファイルをコピーしてくる
    Set-Variable -name CDI_SMART_FILE_NAME -value "DiskInfo.txt" -option constant
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

    [object] $smart = [Smart]::new($copiedCdiSmartFilePath)

    [array] $diskList = $smart.findDiskList()
    [object] $smartInfo = $smart.extractSmart($diskList)

    $smartInfo | ConvertTo-Json -Depth 5 | Out-File "./data/smart.json" -Encoding utf8
    # $smartInfo | ConvertTo-Html | Out-File "./data/smart.html" -Encoding utf8
}
