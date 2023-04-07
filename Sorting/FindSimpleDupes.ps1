# Import the CSV file
$csvData = Import-Csv -Path "input.csv"

# Process the CSV data and find duplicates
$filteredData = $csvData | Group-Object -Property "Resource Name", "Logs" | Where-Object { $_.Count -gt 1 } | ForEach-Object {
    $_.Group
}

# Export the filtered data to a new CSV file
$filteredData | Export-Csv -Path "output.csv" -NoTypeInformation
