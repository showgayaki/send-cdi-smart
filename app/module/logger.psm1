class Logger {
    [string] $logFilePath

    Logger([string] $logFilePath){
        $this.logFilePath = $logFilePath
        $this.LogRotate()
    }

    [void] LogRotate(){
        $this.Logging("info", "=== Check Logrotate. ===")
        [int] $fileSizeThreshold = 1048576
        [int] $backupThreshold = 3
        [int] $logFileSize = (Get-Item $this.logFilePath).Length

        $this.Logging("info", ("fileSizeThreshold: {0}, logFileSize: {1}" -f $fileSizeThreshold, $logFileSize))
        $this.Logging("info", ("Logrotate: {0}" -f ($fileSizeThreshold -lt $logFileSize)))

        # ファイルサイズによってローテート
        if($fileSizeThreshold -lt $logFileSize){
            # logディレクトリのバックアップログファイル一覧取得
            [string] $logDirectory = Split-Path $this.logFilePath -Parent
            [string] $logFileName = Split-Path $this.logFilePath -Leaf
            [array] $backupFiles = (Get-ChildItem $logDirectory -File -Recurse -Include *.log*)

            # ファイル名：「*.log.[num]」のnumを配列で取得
            [array] $backupNumbers = @()
            foreach($file in $backupFiles){
                try {
                    $num = [int]$file.Name.split(".")[-1]
                }
                catch {
                    $num = 0
                }
                $backupNumbers += $num
            }

            # $backupNumbers配列の最大値がバックアップ数
            [int] $currentBackupCount = ($backupNumbers | Measure-Object -Maximum).Maximum
            # num配列を逆順にする
            # ファイル名：「*.log.[num]」のnumが一番大きなものをまず削除しないといけないので
            [array]::Reverse($backupNumbers)

            foreach($num in $backupNumbers){
                [string] $fileName = "{0}.{1}" -f $this.logFilePath, $num
                [string] $rename = "{0}.{1}" -f $this.logFilePath, [int]($num + 1)

                if($num -eq $backupThreshold){
                    Remove-Item $fileName
                    $this.Logging("info", ("Removed: [{0}]." -f $fileName))
                }elseif($num -eq 0){
                    $this.Logging("info", ("Rename: [{0}] to [{1}]." -f $this.logFilePath, $rename))
                    Rename-Item $this.logFilePath $rename
                }else{
                    $this.Logging("info", ("Rename: [{0}] to [{1}]." -f $fileName, $rename))
                    Rename-Item $fileName $rename
                }
            }
        }

        $this.Logging("info", "=== Start send-cdi-smart. ===")
    }

    [void] Logging([string] $level, [string] $log){
        [string] $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
        [string] $logString = "[{0}] [{1}]: {2}" -f $now, $level, $log
        Add-Content -Path $this.logFilePath -Value $logString
    }
}
