class IniFile {
    [object] IniToJson([string] $iniFilePath){
        [object] $config = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
        [object] $section = $null
        [string] $sectionName = ""

        Import-Csv -Path $iniFilePath -Header Key,Value -Delimiter "=" |
        ForEach-Object {
            [string] $key = ""
            [string] $value = ""

            # コメント行は飛ばす
            if($_.Key.Trim()[0] -eq ";" -Or $_.Key.Trim()[0] -eq "#" ){
                return
            }
            # Valueが取れない(「=」がない)場合はセクションの表記
            if($null -eq $_.Value){
                # 次のセクションが出てきたので、前の行までのセクションを$configに入れる
                if($section.Count -gt 0){
                    $config.Add($sectionName, $section)
                }

                # コメント部分の削除
                $key = ($_.Key -split "#")[0].Trim()
                $key = ($key -split ";")[0].Trim()
                # セクション名を取得して、セクションDictionaryの初期化
                $sectionName = $key.Replace("[", "").Replace("]", "")
                $section = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
            }else{
                # Valueが取れた(「=」がある)場合の処理
                $key = $_.Key
                # コメント削除
                $value = ($_.Value -split "#")[0].Trim()
                $value = ($value -split ";")[0].Trim()

                # セクション中なら$sectionにAddする
                if($sectionName -ne ""){
                    $section.Add($key, $value)
                }
            }
            # セクションじゃない場合
            if($sectionName -eq ""){
                $config.Add($key, $value)
            }
        }
        # iniファイル最終行は次のセクション表記がないので
        # $sectionが取れていれば$configに入れる
        if($section.Count -gt 0){
            $config.Add($sectionName, $section)
        }
        return $config
    }
}
