# send-cdi-smart
[CrystalDiskInfo](https://crystalmark.info/ja/software/crystaldiskinfo/)で取得したS.M.A.R.T.情報をメールで送信する。  
[CrystalDiskInfoのコマンドライン](https://crystalmark.info/ja/software/crystaldiskinfo/crystaldiskinfo-advanced-features/)を利用。


## 環境
`$PSVersionTable`  
```
Name                           Value
----                           -----
PSVersion                      7.3.4
PSEdition                      Core
GitCommitId                    7.3.4
OS                             Microsoft Windows 10.0.22621
Platform                       Win32NT
PSCompatibleVersions           {1.0, 2.0, 3.0, 4.0…}
PSRemotingProtocolVersion      2.3
SerializationVersion           1.1.0.1
WSManStackVersion              3.0
```

## ライブラリインストール
SmtpClientは[廃止](https://learn.microsoft.com/ja-jp/dotnet/api/system.net.mail.smtpclient?view=net-7.0#remarks)だそうなので、代わりにMailKitとMimeKitを使う。  

以下のコマンドを実行してインストール。  
`Install-Package -name "MimeKit" -Source "https://www.nuget.org/api/v2" -SkipDependencies`  
`Install-Package -name "MailKit" -Source "https://www.nuget.org/api/v2"`  

参考動画：[PowerShell Tutorials : Send an email using MailKit](https://www.youtube.com/watch?v=wy5vs0gEei0)


## config.json
config.json.sampleにメール情報を記載してconfig.jsonにリネーム。  
以下はサンプル
```
{
    "CDI_DIRECTORY": "C:\\Program Files\\CrystalDiskInfo",
    "CDI_EXE_FILE": "DiskInfo64.exe",
    "CDI_OPTION": "/CopyExit",
    "MAIL": {
        "SMTP_SERVER": "smtp.gmail.com",
        "SMTP_PORT": 587,
        "SMTP_USER": "soushinmoto-email-address",
        "SMTP_PASS": "soushinmoto-email-password",
        "TO": "okuritai-email-address"
    },
    "MAIL_LIBRARIES": {
        "MAIL_KIT": "C:\\Program Files\\PackageManagement\\NuGet\\Packages\\MailKit.4.0.0\\lib\\netstandard2.0\\MailKit.dll",
        "MIME_KIT": "C:\\Program Files\\PackageManagement\\NuGet\\Packages\\MimeKit.4.0.0\\lib\\netstandard2.0\\MimeKit.dll"
    }
}
```

## タスクスケジューラに登録
### 全般
- [x] ユーザーがログオンしているかどうかにかかわらず実行する
- [x] 最上位の特権で実行する

- 構成：Windows 10

### 　トリガー
実行したい時間に適当に

### 操作
新規  
- プログラムの開始
- プログラム/スクリプト： `"C:\Program Files\PowerShell\7\pwsh.exe"`
- 引数の追加（オプション）： `-ExecutionPolicy RemoteSigned -File "run.ps1"`
- 開始（オプション）： `D:\Projects\send-cdi-smart`


## メールサンプル
![mail-sample](https://github.com/showgayaki/send-cdi-smart/assets/47170845/6ac35ec3-8110-4bc3-8cb9-151adb4e2fcb)
