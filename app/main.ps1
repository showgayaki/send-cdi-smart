. "./app/ini"


function Main([string] $iniFilePath, [object] $logger) {
    # 設定iniファイル読み込み
    $logger.Logging("info", "Load ini file [{0}]." -f $iniFilePath)
    [object] $ini = [IniFile]::new()
    [object] $config = $ini.IniToJson($iniFilePath)
    # $config.GetType()

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

    # # CDIの設定ファイルをdataディレクトリにコピー
    # if(Test-Path $cdiIniFilePath){
    #     $logger.Logging("info", ("Copy [{0}] to [{1}]." -f $cdiIniFilePath, $copyDestinationDirectory))
    #     Copy-Item -Path $cdiIniFilePath -Destination $copyDestinationDirectory -Force
    # }else{
    #     $logger.Logging("error", ("[{0}] is NOT exists." -f $cdiIniFilePath))
    # }
    # コピーしたCDI設定ファイルを読み込み
    [string] $copiedCdiIniFilePath = "{0}\{1}" -f $copyDestinationDirectory, $cdiIniFileName
    [object] $cdiConfig = $ini.IniToJson($copiedCdiIniFilePath)

    # # CDIのSmartファイルをdataディレクトリにコピー
    # [string] $smartDirectory = $cdiDirectory + "\Smart"
    # if(Test-Path $smartDirectory){
    #     $logger.Logging("info", ("Copy [{0}] to [{1}]." -f $smartDirectory, $copyDestinationDirectory))
    #     # Smart.iniファイルだけをコピー
    #     Copy-Item -Filter Smart.ini -Recurse $smartDirectory -Destination $copyDestinationDirectory -Force
    # }

    # コピーしたSmartディレクトリ
    [string] $copiedSmartDirectory = $copyDestinationDirectory + "\Smart"
    [array] $smartDirectoryList = Get-ChildItem $copiedSmartDirectory -Directory -Name
    [array] $driveLetters = [char[]](67..90)  # C~Z

    [object] $smartInfo = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
    [string] $driveLetterSectionName = $config["DRIVE_LETTER_SECTION_NAME"]
    foreach($dir in $smartDirectoryList){
        [object] $smartPerDisk = [System.Collections.Generic.Dictionary[String, PSObject]]::new()

        # ドライブレター抜き出し
        $driveLetterIndex = $cdiConfig[$driveLetterSectionName][$dir]
        $smartPerDisk.Add("driveLetter", $driveLetters[$driveLetterIndex])
        # Smart情報抜き出し
        [string] $copiedSmartFilePath = "{0}\{1}\Smart.ini" -f $copiedSmartDirectory, $dir
        [object] $smart = $ini.IniToJson($copiedSmartFilePath)

        $smartPerDisk.Add("smart", $smart)
        $smartInfo.Add($dir, $smartPerDisk)
    }

    # ドライブレターでソート
    # https://stackoverflow.com/questions/60687333/sort-a-nested-hash-table-by-value
    $sortedSmartInfo = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
    $smartInfo.GetEnumerator() | Sort-Object {
        # Sort by first key from each inner hashtable
        $_.Value.driveLetter | Select-Object -First 1
    } | ForEach-Object {
        # re-assign to our ordered dictionary
        $sortedSmartInfo[$_.Key] = $_.Value
    }
    $sortedSmartInfo | ConvertTo-Json -Depth 5 | Out-File "./data/smart.json" -Encoding utf8
    $sortedSmartInfo | ConvertTo-Html | Out-File "./data/smart.html" -Encoding utf8
}
