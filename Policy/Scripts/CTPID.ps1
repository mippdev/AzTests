$dataset = Import-Csv "CSV"
$datasetColumn = $dataset.CloudTrailEvent
foreach ($itm in $datasetColumn)
    {
        $splitEvent = $itm -split ","
        foreach ($split in $splitEvent)
            {
                if ($split -like "*principalid*")
                    {
                        $splitId = $split -split "`""
                        $princID = $splitID[3]
                        $line = New-Object System.Object
                        $line | Add-Member -MemberType NoteProperty -Name "PrincipalID" -Value $princID
                        $OutputArray += $line
                    }
            }
    }
$OutputArray = $OutputArray | Select-Object $_.'PrincipalID' -Unqiue
$OutputArray | Export-Csv -Path .\Output.csv