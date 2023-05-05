class Logger {
    [string] $logFilePath

    Logger([string] $logFilePath){
        $this.logFilePath = $logFilePath
    }

    [void] Logging([string] $level, [string] $log){
        [string] $now = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
        [string] $logString = "[{0}] [{1}]: {2}" -f $now, $level, $log
        Add-Content -Path $this.logFilePath -Value $logString
    }
}
