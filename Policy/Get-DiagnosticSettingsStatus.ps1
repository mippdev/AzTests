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
                MissingCategories                 = @()
                EnabledCategories                 = @()
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

        $diagnosticSettings = $resource.diag | ConvertFrom-Json
        if ($null -eq $diagnosticSettings) {
            $statusObject = New-Object PSObject -Property @{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $null
                HasDiagnosticSettings             = $false
                MissingCategories                 = @()
                EnabledCategories                 = @()
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
            $requiredCategories = $evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] }
            $enabledRequiredCategories = @()
            foreach ($category in $requiredCategories) {
                if ($diag.LogCategories -contains $category) {
                    $enabledRequiredCategories += $category
                }
            }

            $statusObject = New-Object PSObject -Property @{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $diag.Name
                HasDiagnosticSettings             = $true
                MissingCategories                 = $requiredCategories | Where-Object { $_ -notin $diag.LogCategories }
                EnabledCategories                 = $diag.LogCategories
                IsEvalDataExist                   = $true
                EnabledCategoryCount              = $diag.LogCategories.Count
                EnabledRequiredCategoryCount      = $enabledRequiredCategories.Count
                RequiredCategoryCount             = $requiredCategories.Count
                HasAllRequiredCategoriesEnabled   = ($enabledRequiredCategories.Count -eq $requiredCategories.Count)
                HasOnlyRequiredCategoriesEnabled  = ($diag.LogCategories.Count -eq $requiredCategories.Count) -and ($enabledRequiredCategories.Count -eq $requiredCategories.Count)
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
