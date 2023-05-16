class Html{
    [string] $baseHtmlPath
    [string] $htmlContent

    Html([string] $baseHtmlPath){
        $this.baseHtmlPath = $baseHtmlPath
        $this.htmlContent = Get-Content $this.baseHtmlPath -Raw
    }

    [string] BuildHtmlContent([object] $smartAll){
        [string] $content = "<div class=`"container`">`r`n"
        foreach($driveLetter in $smartAll.Keys){
            $content += "<div class=`"driveLetter`">`r`n"
            $content += "<h2>${driveLetter}ドライブ</h2>`r`n"
            $content += "<div class=`"disks`">`r`n"
            foreach($disk in $smartAll.$driveLetter.Keys){
                $content += "<div class=`"smart-per-disk`">`r`n"
                $content += "<h3>${disk}</h3>`r`n"
                $content += "<table>`r`n"
                $content += "<thead>`r`n"
                $content += "<tr>`r`n"
                foreach($header in $smartAll.$driveLetter.$disk.SmartHeader){
                    $content += "<th>" + $header + "</th>"
                }
                $content += "</tr>`r`n"
                $content += "</thead>`r`n"
                $content += "<tbody>`r`n"
                foreach($smart in $smartAll.$driveLetter.$disk.Smart){
                    $content += "<tr>`r`n"
                    [string] $class = ""
                    for([int] $i = 0; $i -lt $smart.Length; $i++){
                        if($i -gt 1){
                            $class = " class=`"number`""
                        }
                        $content += "<td${class}>" + $smart[$i] + "</td>"
                    }
                    $content += "`r`n</tr>`r`n"
                }
                $content += "</tbody>`r`n"
                $content += "</table>`r`n"
                $content += "</div>`r`n"
            }
            $content += "</div>`r`n"
            $content += "</div>`r`n"
        }
        $content += "</div>`r`n"

        [string] $html = $this.htmlContent.Replace("{{ content }}", $content)
        return $html
    }
}
