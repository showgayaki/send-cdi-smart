class Smart {
    [string] $smartFilePath
    [string] $smartFileContent

    Smart([string] $smartFilePath){
        $this.smartFilePath = $smartFilePath
        $this.smartFileContent = Get-Content $this.smartFilePath -Raw
    }

    [array] findDiskList(){
        <#
        return [
            "(01) KIOXIA-EXCERIA PLUS G2 SSD",
            "(02) CT2000BX500SSD1",
            "(03) CT2000BX500SSD1"
            ]
        #>
        [array] $diskList = $this.smartFileContent.split(
            "-- Disk List ---------------------------------------------------------------`r`n"
            )[1].split(
                "`r`n`r`n----------------------------------------------------------------------------"
            )[0].split("`r`n") | foreach{
                $_.split(":")[0].Trim()
            }
        return $diskList
    }

    [object] extractSmart([array] $diskList){
        [object] $smartInfo = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
        # ディスクごとに詳細とSMART情報を抜き出してjsonにする
        foreach($disk in $diskList){
            # return用Dictionary
            [object] $smartPerDisk = [System.Collections.Generic.Dictionary[String, PSObject]]::new()

            # ディスクの詳細とSMART箇所を抜き出す
            [string] $diskDetail = $this.smartFileContent.split(
                $disk + "`r`n" +
                "----------------------------------------------------------------------------`r`n"
            )[1].split(
                "`r`n`r`n-- IDENTIFY_DEVICE ---------------------------------------------------------"
            )[0]

            # ディスク詳細とSMART情報箇所に分割
            [string] $detail, [string] $smart = $diskDetail.split(
                "`r`n`r`n-- S.M.A.R.T. --------------------------------------------------------------`r`n"
            )

            # 詳細部分の処理
            $detail.split("`r`n") | foreach -Process{
                [array] $splited = $_.split(":").Trim()
                # 1行目はModel
                if($splited[0] -eq "Model"){
                    [string] $model = $splited[1]
                }elseif($splited[0] -eq "Serial Number") {
                    # 同モデルのディスクがあるかもしれないので、モデル名にシリアルNoを足しておく
                    $model = "{0}_{1}" -f $model, $splited[1]
                }else{
                    $smartPerDisk.Add($splited[0].Replace(" ", "").Trim(), $splited[1].Trim())
                }
            } -End{
                $smartInfo.Add($model, $smartPerDisk)
            }


            <#
            --- input ---
            ID RawValues(6) Attribute Name
            01 000000000000 クリティカルワーニング
            04 000000000005 予備領域 (しきい値)
            -------------
            #>
            [array] $smartHeader = @()
            $smart.split("`r`n") | foreach -Process{
                [object] $smartPerId = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
                [object] $smartValues = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
                [array] $smartRow = @()

                [array] $columns = $_.split(" ")
                for([int] $i = 0; $i -lt $columns.Length; $i++){
                    if($_.Contains("ID")){
                        if($columns[$i] -eq "Name"){
                            $smartHeader[-1] += $columns[$i]
                        }else{
                            $smartHeader += $columns[$i]
                        }
                    }else{
                        if($i + 1 -gt $smartHeader.Length){
                            $smartRow[-1] += $columns[$i]
                        }else{
                            $smartRow += $columns[$i]
                        }
                    }
                }

                for([int] $i = 0; $i -lt $smartRow.Length; $i++){
                    if($i -gt 0){
                        $smartValues.Add($smartHeader[$i], $smartRow[$i])
                    }

                    if($i -eq $smartRow.Length - 1){
                        $smartPerId.Add($smartRow[0], $smartValues)
                        $smartPerDisk["Smart"] += $smartPerId
                    }
                }
            } -End{
                # SMART情報のIDでソート
                # https://stackoverflow.com/questions/60687333/sort-a-nested-hash-table-by-value
                $sortedSmartPerDisk = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
                $smartPerDisk["Smart"].GetEnumerator() | Sort-Object {
                    # Sort by first key from each inner hashtable
                    $_.Key | Select-Object -First 1
                } | ForEach-Object {
                    # re-assign to our ordered dictionary
                    $sortedSmartPerDisk[$_.Key] = $_.Value
                }
                $smartPerDisk["Smart"] = $sortedSmartPerDisk
            }
        }
        return $smartInfo
    }
}
