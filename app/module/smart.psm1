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

    [object] findDetailAndSmart([string] $diskName, [string] $content){
        # ディスクの詳細とSMART箇所を抜き出す
        [string] $detailAndSmart = $content.split(
            $diskName + "`r`n" +
            "----------------------------------------------------------------------------`r`n"
        )[1].split(
            "`r`n`r`n-- IDENTIFY_DEVICE ---------------------------------------------------------"
        )[0]

        # ディスク詳細とSMART情報箇所に分割
        [string] $detail, [string] $smart = $detailAndSmart.split(
            "`r`n`r`n-- S.M.A.R.T. --------------------------------------------------------------`r`n"
        )

        # Dictionaryにして返す
        [object] $detailAndSmartDictionary = [System.Collections.Generic.Dictionary[String, String]]::new()
        $detailAndSmartDictionary.Add("detail", $detail)
        $detailAndSmartDictionary.Add("smart", $smart)

        return $detailAndSmartDictionary
    }

    [object] extractSmart(){
        # ディスクリスト取得
        [array] $diskList = $this.findDiskList()
        # すべてのディスクのSMART情報用Dictionary
        [object] $smartAll = [System.Collections.Generic.Dictionary[String, PSObject]]::new()

        # ディスクごとに詳細とSMART情報を抜き出してjsonにする
        foreach($diskName in $diskList){
            # ディスクごとのDictionary
            [object] $smartPerDisk = [System.Collections.Generic.Dictionary[String, PSObject]]::new()

            # ディスクの詳細とSMART箇所を抜き出す
            [object] $diskDetailAndSmart = $this.findDetailAndSmart($diskName, $this.smartFileContent)
            [string] $detail = $diskDetailAndSmart["detail"]
            [string] $smart = $diskDetailAndSmart["smart"]

            # 詳細部分の処理
            # --- Input Ex ---
            # Model : KIOXIA-EXCERIA PLUS G2 SSD
            # Firmware : ECFA11.3
            # -------------
            [array] $detailLines = $detail.split("`r`n")
            foreach($line in $detailLines){
                [array] $splited = $line.split(":").Trim()
                # 1行目はModel
                if($splited[0] -eq "Model"){
                    [string] $model = $splited[1]
                }elseif($splited[0] -eq "Serial Number") {
                    # 同モデルのディスクがあるかもしれないので、モデル名にシリアルNoを足しておく
                    $model = "{0}_{1}" -f $model, $splited[1]
                }else{
                    # 「:」あとのValueから前後・文字間のスペースを削除してAdd
                    $smartPerDisk.Add($splited[0].Replace(" ", "").Trim(), $splited[1].Trim())
                }
            }
            $smartAll.Add($model, $smartPerDisk)

            # SMART部分の処理
            # --- Input Ex ---
            # ID RawValues(6) Attribute Name
            # 01 000000000000 クリティカルワーニング
            # 04 000000000005 予備領域 (しきい値)
            # -------------
            [array] $smartHeader = @()
            [array] $smartLines = $smart.split("`r`n")
            foreach($line in $smartLines){
                [object] $smartPerId = [System.Collections.Generic.Dictionary[String, PSObject]]::new()
                [object] $smartValues = [System.Collections.Generic.Dictionary[String, String]]::new()
                [array] $smartDataRow = @()

                # 行の値ごとの処理
                # 「Attribute Name」カラムには半角スペースが入っていることがあるため
                # 半角スペースでSplitすると、ヘッダー行の長さとデータ行の長さがズレる
                # そのため、いったん半角スペースを取り除いてヘッダー・データを配列に入れておく
                [array] $columns = $line.split(" ")
                for([int] $i = 0; $i -lt $columns.Length; $i++){
                    if($line.Contains("ID")){
                        # 「Attribute Name」の間のスペースなくして結合
                        if($columns[$i] -eq "Name"){
                            $smartHeader[-1] += $columns[$i]
                        }else{
                            $smartHeader += $columns[$i]
                        }
                    }else{
                        # 「Attribute Name」→ 「AttributeName」にしたので
                        # 「SMART配列の長さ > ヘッダー配列の長さ」になっている
                        # なので、SMART配列のインデックスがヘッダー配列長さを超えたら直前の値に結合する
                        if($i -gt $smartHeader.Length - 1){
                            $smartDataRow[-1] += $columns[$i]
                        }else{
                            $smartDataRow += $columns[$i]
                        }
                    }
                }

                # データ行の処理
                for([int] $i = 0; $i -lt $smartDataRow.Length; $i++){
                    # ID: {"RawValues(6)": "XXX", ...}
                    # の形にするので、いったんIDカラムは除いて値を取る
                    if($i -gt 0){
                        $smartValues.Add($smartHeader[$i], $smartDataRow[$i])
                    }

                    # 行の最後の要素での処理
                    if($i -eq $smartDataRow.Length - 1){
                        # ID: {"RawValues(6)": "XXX", ...} の形でAdd
                        $smartPerId.Add($smartDataRow[0], $smartValues)
                        $smartPerDisk["Smart"] += $smartPerId
                    }
                }
            }

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
        return $smartAll
    }
}
