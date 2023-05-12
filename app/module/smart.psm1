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

    [array] sortArray([array] $array){
        # [ID, AttributeName, 各項目｡｡｡]の順にする
        [array] $firstColumn = $array[0]
        [array] $arrayCenter = $array[1..($array.Length - 2)]
        [array] $lastColumn = $array[-1]

        [array] $sortedArray = $firstColumn + $lastColumn + $arrayCenter
        return $sortedArray
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
                [array] $smartDataRow = @()

                # 行の値ごとの処理
                # 「Attribute Name」カラムには半角スペースが入っていることがあるため
                # 半角スペースでSplitすると、ヘッダー行配列の長さとデータ行配列の長さがズレることがある
                # そのため、いったん半角スペースを取り除いてヘッダー・データを配列に入れておく
                [array] $columns = $line.split(" ")
                for([int] $i = 0; $i -lt $columns.Length; $i++){
                    # DiskInfo.txtで、桁揃えに使われているアンダースコアは削除
                    $columns[$i] = $columns[$i].Replace("_", "")
                    # ヘッダー行
                    if($line.Contains("ID")){
                        # 「Attribute Name」の間のスペースなくして結合
                        if($columns[$i] -eq "Name"){
                            $smartHeader[-1] += $columns[$i]
                        }else{
                            $smartHeader += $columns[$i]
                        }
                    }else{
                        # 「Attribute Name」→ 「AttributeName」にしたので
                        # 「データ配列の長さ > ヘッダー配列の長さ」になっていることがある
                        # なので、SMART配列のインデックスがヘッダー配列長さを超えたら直前の値に結合する
                        if($i -gt $smartHeader.Length - 1){
                            $smartDataRow[-1] += $columns[$i]
                        }else{
                            $smartDataRow += $columns[$i]
                        }
                    }
                }

                if($smartPerDisk["SmartHeader"] -eq $null){
                    [array] $sortedSmartHeader = $this.sortArray($smartHeader)
                    $smartPerDisk["SmartHeader"] = $sortedSmartHeader
                }

                [array] $sortedSmartDataRow = @()
                if($smartDataRow -ne $null){
                    $sortedSmartDataRow = $this.sortArray($smartDataRow)
                }

                # SMART情報をDictionaryに登録
                if($smartPerDisk["Smart"] -eq $null){
                    $smartPerDisk["Smart"] = $sortedSmartDataRow
                }else{
                    # 2行目以降は追加
                    # 追加の場合は「+=」と変数前のカンマが必要らしい
                    $smartPerDisk["Smart"] += ,$sortedSmartDataRow
                }
            }
        }
        return $smartAll
    }
}
