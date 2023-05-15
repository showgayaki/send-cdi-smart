class Mail {
    [string] $computerName
    [hashtable] $mailConfig
    [hashtable] $mailLibraries

    Mail([hashtable] $mailConfig, [hashtable] $mailLibraries){
        $this.computerName = (Get-Content Env:COMPUTERNAME)
        $this.mailConfig = $mailConfig
        $this.mailLibraries = $mailLibraries
    }

    [hashtable] SendMail([string] $mailBody){
        Add-Type -Path $this.mailLibraries.MAIL_KIT
        Add-Type -Path $this.mailLibraries.MIME_KIT

        $from = $this.mailConfig.SMTP_USER
        $password = $this.mailConfig.SMTP_PASS
        $smtp = New-Object MailKit.Net.Smtp.SmtpClient
        $message = New-Object MimeKit.MimeMessage
        $builder = New-Object MimeKit.BodyBuilder

        $message.From.Add($from)
        $message.To.Add($this.mailConfig.TO)
        $message.Subject = "S.M.A.R.T. Info from $($this.computerName)"
        $builder.HtmlBody = $mailBody
        $message.Body = $builder.ToMessageBody()

        try {
            $smtp.Connect($this.mailConfig.SMTP_SERVER, $this.mailConfig.SMTP_PORT, $false) -ErrorAction Stop
            # $password = ConvertTo-SecureString $this.mailConfig.SMTP_PASS -AsPlainText -Force
            # $credential = New-Object System.Management.Automation.PSCredential($from, $password)
            # $smtp.Authenticate($credential.username, $credential.password)
            $smtp.Authenticate($from, $password)
            $smtp.Send($message)
            return @{ "done" = $true }
        }
        catch {
            return @{
                "done" = $false
                "message" = $PSItem.Exception.Message
            }
        }
        finally {
            $smtp.Disconnect($true)
            $smtp.Dispose()
        }
    }
}
