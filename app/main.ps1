using module "./module/ini.psm1"
using module "./module/smart.psm1"


function Main([string] $iniFilePath, [object] $logger) {
    # 設定iniファイル読み込み
    $logger.Logging("info", "Load ini file [{0}]." -f $iniFilePath)
    [object] $ini = [IniFile]::new()
    [object] $config = $ini.IniToJson($iniFilePath)

    # コピー先ディレクトリがなかったら作成
    if(!(Test-Path "./data")){
        New-Item "./data" -ItemType Directory
    }
    # コピー先のディレクトリ
    [string] $copyDestinationDirectory = Convert-Path "./data"

    # CDIの設定ファイルをコピーしてくる
    [string] $cdiDirectory = $config['CDI_DIRECTORY']
    [string] $cdiIniFileName = "DiskInfo.ini"
    [string] $cdiIniFilePath = "{0}\{1}" -f $cdiDirectory, $cdiIniFileName

    # CDIの設定ファイルをdataディレクトリにコピー
    if(Test-Path $cdiIniFilePath){
        $logger.Logging("info", ("Copy [{0}] to [{1}]." -f $cdiIniFilePath, $copyDestinationDirectory))
        Copy-Item -Path $cdiIniFilePath -Destination $copyDestinationDirectory -Force
    }else{
        $logger.Logging("error", ("[{0}] is NOT exists." -f $cdiIniFilePath))
    }
    # コピーしたCDI設定ファイルを読み込み
    [string] $copiedCdiIniFilePath = "{0}\{1}" -f $copyDestinationDirectory, $cdiIniFileName
    [object] $cdiConfig = $ini.IniToJson($copiedCdiIniFilePath)

    # CDIのSmartファイルをdataディレクトリにコピー
    [string] $smartDirectory = $cdiDirectory + "\Smart"
    if(Test-Path $smartDirectory){
        $logger.Logging("info", ("Copy [{0}] to [{1}]." -f $smartDirectory, $copyDestinationDirectory))
        # Smart.iniファイルだけをコピー
        Copy-Item -Filter Smart.ini -Recurse $smartDirectory -Destination $copyDestinationDirectory -Force
    }

    # コピーしたSmartディレクトリ
    [string] $copiedSmartDirectory = $copyDestinationDirectory + "\Smart"
    # Smart情報抽出
    $smart = [Smart]::new($config, $cdiConfig, $copiedSmartDirectory)
    $smartInfo = $smart.extractSmart()

    $smartInfo | ConvertTo-Json -Depth 5 | Out-File "./data/smart.json" -Encoding utf8
    $smartInfo | ConvertTo-Html | Out-File "./data/smart.html" -Encoding utf8
}
