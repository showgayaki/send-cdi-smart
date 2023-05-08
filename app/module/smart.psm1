using module "./ini.psm1"


class Smart: IniFile {
    [object] $config
    [object] $cdiConfig
    [object] $smartDirectory

    Smart([object] $config, [object] $cdiConfig, [string] $smartDirectory){
        $this.config = $config
        $this.cdiConfig = $cdiConfig
        $this.smartDirectory = $smartDirectory
    }

    [object] extractSmart(){
        [array] $driveLetters = [char[]](67..90)  # C~Z
        [array] $smartDirectoryList = Get-ChildItem $this.smartDirectory -Directory -Name

        [object] $smartInfo = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
        [string] $driveLetterSectionName = $this.config["DRIVE_LETTER_SECTION_NAME"]
        foreach($dir in $smartDirectoryList){
            [object] $smartPerDisk = [System.Collections.Generic.Dictionary[String, PSObject]]::new()

            # ドライブレター抜き出し
            $driveLetterIndex = $this.cdiConfig[$driveLetterSectionName][$dir]
            $smartPerDisk.Add("driveLetter", $driveLetters[$driveLetterIndex])
            # Smart情報抜き出し
            [string] $smartFilePath = "{0}\{1}\Smart.ini" -f $this.smartDirectory, $dir
            [object] $smart = ([IniFile]$this).IniToJson($smartFilePath)

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

        return $sortedSmartInfo
    }
}
