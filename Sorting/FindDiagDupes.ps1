# Import the CSV file
$csvData = Import-Csv -Path "input.csv"

# Process the CSV data and find duplicates
$filteredData = $csvData | Group-Object -Property "Resource Name" | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    $duplicates = $_.Group
    $logs = $duplicates | ForEach-Object { $_.Logs -split '},' | ForEach-Object { $_.Trim() } }
    $intersectLogs = $logs | Group-Object | Where-Object { $_.Count -gt 1 } | Select-Object -ExpandProperty Name

    if ($intersectLogs) {
        $duplicates
    }
}

# Export the filtered data to a new CSV file
$filteredData | Export-Csv -Path "output.csv" -NoTypeInformation
