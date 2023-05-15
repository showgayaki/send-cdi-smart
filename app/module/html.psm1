class Html{
    [string] $baseHtmlPath
    [string] $htmlContent

    Html([string] $baseHtmlPath){
        $this.baseHtmlPath = $baseHtmlPath
        $this.htmlContent = Get-Content $this.baseHtmlPath -Raw
    }

    [string] BuildHtmlContent([object] $smartAll){
        [string] $content = ""
        foreach($diskName in $smartAll.Keys){
            $content += "<div class=`"smart-per-disk`">`r`n"
            $content += "<h2>$diskName</h2>`r`n"
            $content += "<p>$($smartAll.$diskName.Firmware)</p>`r`n"

            $content += "<table>`r`n"
            $content += "<thead>`r`n"
            $content += "<tr>`r`n"
            foreach($header in $smartAll[$diskName]["SmartHeader"]){
                $content += "<th>" + $header + "</th>"
            }
            $content += "</tr>`r`n"
            $content += "</thead>`r`n"

            $content += "<tbody>`r`n"
            foreach($smart in $smartAll[$diskName]["Smart"]){
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

        [string] $html = $this.htmlContent.Replace("{{ content }}", $content)
        return $html
    }
}
