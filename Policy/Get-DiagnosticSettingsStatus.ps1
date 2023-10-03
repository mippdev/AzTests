function Get-DiagnosticSettingsStatus {
    param (
        [Hashtable]$resourceEval,
        [Object]$resourceData
    )

    $output = @()

    foreach ($resource in $resourceData) {
        $resourceTypeKind = "$($resource.res.Type)|$($resource.res.Kind)"
        $evalData = $resourceEval[$resourceTypeKind]

        if ($null -eq $evalData) {
            $statusObject = New-Object PSObject -Property @{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $null
                HasDiagnosticSettings             = $false
                MissingCategories                 = ""
                EnabledCategories                 = ""
                IsEvalDataExist                   = $false
                EnabledCategoryCount              = 0
                EnabledRequiredCategoryCount      = 0
                RequiredCategoryCount             = 0
                HasAllRequiredCategoriesEnabled   = $false
                HasOnlyRequiredCategoriesEnabled  = $false
            }
            $output += $statusObject
            continue
        }

        $diagnosticSettings = $resource.diag # Assuming diag is already an array/object, remove ConvertFrom-Json if needed
        if ($null -eq $diagnosticSettings) {
            $statusObject = New-Object PSObject -Property @{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $null
                HasDiagnosticSettings             = $false
                MissingCategories                 = ""
                EnabledCategories                 = ""
                IsEvalDataExist                   = $true
                EnabledCategoryCount              = 0
                EnabledRequiredCategoryCount      = 0
                RequiredCategoryCount             = $evalData.LogCategories.Keys.Count
                HasAllRequiredCategoriesEnabled   = $false
                HasOnlyRequiredCategoriesEnabled  = $false
            }
            $output += $statusObject
            continue
        }

        foreach ($diag in $diagnosticSettings) {
            $requiredCategories = $evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] -eq $true }
            $enabledCategories = $diag.properties.logs | Where-Object { $_.enabled -eq $true } | ForEach-Object { $_.category }

            $statusObject = New-Object PSObject -Property @{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $diag.name
                HasDiagnosticSettings             = $true
                MissingCategories                 = ($requiredCategories | Where-Object { $_ -notin $enabledCategories }) -join ','
                EnabledCategories                 = $enabledCategories -join ','
                IsEvalDataExist                   = $true
                EnabledCategoryCount              = $enabledCategories.Count
                EnabledRequiredCategoryCount      = ($requiredCategories | Where-Object { $_ -in $enabledCategories }).Count
                RequiredCategoryCount             = $requiredCategories.Count
                HasAllRequiredCategoriesEnabled   = ($requiredCategories.Count -eq ($requiredCategories | Where-Object { $_ -in $enabledCategories }).Count)
                HasOnlyRequiredCategoriesEnabled  = ($enabledCategories.Count -eq $requiredCategories.Count) -and ($requiredCategories.Count -eq ($requiredCategories | Where-Object { $_ -in $enabledCategories }).Count)
            }
            $output += $statusObject
        }
    }

    return $output
}

# Example of usage
$diagnosticSettingsStatus = Get-DiagnosticSettingsStatus -resourceEval $resourceEval -resourceData $resourceData

# Exporting to CSV
$diagnosticSettingsStatus | Export-Csv -Path 'DiagnosticSettingsStatus.csv' -NoTypeInformation
