class Html{
    [string] $htmlTemplateDirectory
    [string] $cssContent
    [string] $htmlContent

    Html([string] $htmlTemplateDirectory){
        $this.htmlTemplateDirectory = $htmlTemplateDirectory
        $this.cssContent = Get-Content ($this.htmlTemplateDirectory + "\css\style.css") -Raw
        $this.htmlContent = Get-Content ($this.htmlTemplateDirectory + "\base.html") -Raw

        $this.htmlContent = $this.htmlContent.Replace("{{ style }}", $this.cssContent)
    }

    [hashtable] HealthStatus([string] $healthStatus){
        $status, $percantage = $healthStatus.split(" ")
        return @{}
    }

    [string] BuildHtmlContent([object] $smartAll){
        [string] $content = "<div class=`"container`">`r`n"
        foreach($driveLetter in $smartAll.Keys){
            $content += "<div class=`"drive-letter`">`r`n"
            $content += "<h2 class=`"drive-letter__title`">${driveLetter}ドライブ</h2>`r`n"
            $content += "<ul class=`"drive-letter__disk-list disk-list`">`r`n"
            foreach($disk in $smartAll.$driveLetter.Keys){
                [string] $diskName = "{0} {1}" -f $disk.split("_")[0], $smartAll.$driveLetter.$disk.DiskSize
                [string] $temperature = $smartAll.$driveLetter.$disk.Temperature # 温度
                [string] $healthStatus = $smartAll.$driveLetter.$disk.HealthStatus # 健康状態

                [string] $firmware = $smartAll.$driveLetter.$disk.Firmware # ファームウェア
                [string] $serialNumber = $smartAll.$driveLetter.$disk.SerialNumber # シリアルナンバー
                [string] $interface = $smartAll.$driveLetter.$disk.Interface # インターフェース
                [string] $transferMode = $smartAll.$driveLetter.$disk.TransferMode # 対応転送モード
                [string] $standard = $smartAll.$driveLetter.$disk.Standard # 対応規格
                [string] $features = $smartAll.$driveLetter.$disk.Features # 対応機能

                [string] $hostReads = $smartAll.$driveLetter.$disk.HostReads # 総読込量(ホスト)
                [string] $hostWrites = $smartAll.$driveLetter.$disk.HostWrites # 総書込量(ホスト)
                [string] $powerOnHours = $smartAll.$driveLetter.$disk.PowerOnHours # 使用時間
                [string] $powerOnCount = $smartAll.$driveLetter.$disk.PowerOnCount # 電源投入回数

                $content += "<li class=`"disk-list__item disk`">`r`n"
                $content += "<h3 class=`"disk__name`">${diskName}</h3>`r`n"
                $content += "<div class=`"disk__detail disk-detail`">`r`n"

                $content += "<dl class=`"disk-detail__status status`">`r`n"
                $content += "<dt class=`"status__name status__name--health`">健康状態</dt>`r`n"
                $content += "<dd class=`"status__description status__description--health`">{0}</dd>`r`n" -f $healthStatus
                $content += "<dt class=`"status__name status__name--temp`">温度</dt>`r`n"
                $content += "<dd class=`"status__description status__description--temp`">{0}</dd>`r`n" -f $temperature
                $content += "</dl><!-- .disk-detail__status -->`r`n"

                $content += "<dl class=`"disk-detail__spec spec`">`r`n"
                $content += "<dt class=`"spec__item-name`">ファームウェア</dt>`r`n"
                $content += "<dd class=`"spec__description`">{0}</dd>`r`n" -f $firmware
                $content += "<dt class=`"spec__item-name`">シリアルナンバー</dt>`r`n"
                $content += "<dd class=`"spec__description`">{0}</dd>`r`n" -f $serialNumber
                $content += "<dt class=`"spec__item-name`">インターフェース</dt>`r`n"
                $content += "<dd class=`"spec__description`">{0}</dd>`r`n" -f $interface
                $content += "<dt class=`"spec__item-name`">対応転送モード</dt>`r`n"
                $content += "<dd class=`"spec__description`">{0}</dd>`r`n" -f $transferMode
                $content += "<dt class=`"spec__item-name`">対応規格</dt>`r`n"
                $content += "<dd class=`"spec__description`">{0}</dd>`r`n" -f $standard
                $content += "<dt class=`"spec__item-name`">対応機能</dt>`r`n"
                $content += "<dd class=`"spec__description`">{0}</dd>`r`n" -f $features
                $content += "</dl><!-- .disk-detail__spec -->`r`n"

                $content += "<dl class=`"disk-detail__data data`">`r`n"
                $content += "<dt class=`"data__item-name`">総読込量(ホスト)</dt>`r`n"
                $content += "<dd class=`"data__description`">{0}</dd>`r`n" -f $hostReads
                $content += "<dt class=`"data__item-name`">総書込量(ホスト)</dt>`r`n"
                $content += "<dd class=`"data__description`">{0}</dd>`r`n" -f $hostWrites
                $content += "<dt class=`"data__item-name`">電源投入回数</dt>`r`n"
                $content += "<dd class=`"data__description`">{0}</dd>`r`n" -f $powerOnCount
                $content += "<dt class=`"data__item-name`">使用時間</dt>`r`n"
                $content += "<dd class=`"data__description`">{0}</dd>`r`n" -f $powerOnHours
                $content += "</dl><!-- .disk-detail__data -->`r`n"
                $content += "</div><!-- .disk__detail -->`r`n"

                $content += "<table class=`"disk__smart-table smart-table`">`r`n"
                $content += "<thead>`r`n"
                $content += "<tr>`r`n"
                foreach($header in $smartAll.$driveLetter.$disk.SmartHeader){
                    [string] $headerModifier = " smart-table__header--"
                    switch ($header) {
                        "ID" { $headerModifier += "id" }
                        "AttributeName" { $headerModifier += "attribute-name" }
                        "Cur" { $headerModifier += "cur" }
                        "Wor" { $headerModifier += "wor" }
                        "Thr" { $headerModifier += "thr" }
                        "RawValues(6)" { $headerModifier += "row-values" }
                        Default { $headerModifier = "" }
                    }
                    $content += "<th class=`"smart-table__header${headerModifier}`">" + $header + "</th>"
                }
                $content += "</tr>`r`n"
                $content += "</thead>`r`n"

                $content += "<tbody>`r`n"
                foreach($smart in $smartAll.$driveLetter.$disk.Smart){
                    $content += "<tr class=`"smart-table__row`">`r`n"
                    for([int] $i = 0; $i -lt $smart.Length; $i++){
                        [string] $dataModifier = " smart-table__data--"
                        switch ($i) {
                            0 { $dataModifier += "id" }
                            1 { $dataModifier += "attribute-name" }
                            Default { $dataModifier = "" }
                        }
                        if($i -gt 1){
                            $dataModifier = " number"
                        }
                        $content += "<td class=`"smart-table__data${dataModifier}`">" + $smart[$i] + "</td>"
                    }
                    $content += "`r`n</tr>`r`n"
                }
                $content += "</tbody>`r`n"
                $content += "</table>`r`n"
                $content += "</li><!-- .disk -->`r`n"
            }
            $content += "</ul><!-- .disk-list -->`r`n"
            $content += "</div><!-- .driveLetter -->`r`n"
        }
        $content += "</div><!-- .container -->`r`n"

        [string] $html = $this.htmlContent.Replace("{{ content }}", $content)
        return $html
    }
}
