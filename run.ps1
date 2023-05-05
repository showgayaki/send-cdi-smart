. "./app/logger"


function Run {
    # プロジェクトのルートディレクトリ
    Set-Variable -name ROOT_DIR -value @(Split-Path $script:myInvocation.MyCommand.Path -Parent).Trim() -option constant
    # ログ関連
    Set-Variable -name LOG_FILE_NAME -value "send-cdi-smart.log" -option constant
    Set-Variable -name LOG_DIR -value ($ROOT_DIR + "\log") -option constant
    Set-Variable -name LOG_FILE_PATH -value ($LOG_DIR + "\" + $LOG_FILE_NAME) -option constant

    # logディレクトリがなかったら作成
    if(!(Test-Path $LOG_DIR)){
        New-Item $LOG_DIR -ItemType Directory
    }

    # ログ出力開始
    [object] $logger = [Logger]::new($LOG_FILE_PATH)
    $logger.Logging("info", "Start send-cdi-smart.")

    # アプリケーション設定ファイル
    Set-Variable -name INI_FILE_NAME -value "config.ini" -option constant
    Set-Variable -name INI_FILE_PATH -value ($ROOT_DIR + "\" + $INI_FILE_NAME) -option constant

    # 設定ファイルがあれば実行
    if(Test-Path $INI_FILE_PATH){
        . "./app/main"
        Main $INI_FILE_PATH $logger
    }else{
        $logger.Logging("error", "[{0}] is NOT exists." -f $INI_FILE_PATH)
    }

    $logger.Logging("info", "Quit the Application.")
}


Run
