function Get-DiagnosticSettingsStatus {
    param (
        [Hashtable]$resourceEval,
        [Object]$resourceData
    )

    $output = @()

    foreach ($resource in $resourceData) {
        $resourceTypeKind = "$($resource.res.Type)|$($resource.res.Kind)"
        $evalData = $resourceEval[$resourceTypeKind]

        $hasLogCategorySettings = if($null -ne $evalData) { $evalData.HasLogCategorySettings } else { $false }
        $supportsDiagnosticSettings = if($null -ne $evalData) { $evalData.SupportsDiagnosticSettings } else { $false }

        if ($null -eq $evalData) {
            $statusObject = [PSCustomObject]@{
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
                ResHasLogCategorySettings         = $hasLogCategorySettings
                ResSupportsDiagnosticSettings     = $supportsDiagnosticSettings
            }
            $output += $statusObject
            continue
        }

        $diagnosticSettings = $resource.diag | ConvertFrom-Json
        if ($null -eq $diagnosticSettings) {
            $requiredCategories = ($evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] })
            $statusObject = [PSCustomObject]@{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $null
                HasDiagnosticSettings             = $false
                MissingCategories                 = @()
                EnabledCategories                 = @()
                IsEvalDataExist                   = $true
                EnabledCategoryCount              = 0
                EnabledRequiredCategoryCount      = 0
                RequiredCategoryCount             = $requiredCategories.Count
                HasAllRequiredCategoriesEnabled   = $false
                HasOnlyRequiredCategoriesEnabled  = $false
                ResHasLogCategorySettings         = $hasLogCategorySettings
                ResSupportsDiagnosticSettings     = $supportsDiagnosticSettings
            }
            $output += $statusObject
            continue
        }

        foreach ($diag in $diagnosticSettings) {
            $requiredCategories = ($evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] })
            $enabledRequiredCategories = @()
            foreach ($category in $requiredCategories) {
                if ($diag.properties.logs.category -contains $category) {
                    $enabledRequiredCategories += $category
                }
            }

            $statusObject = [PSCustomObject]@{
                ResourceId                        = $resource.id
                ResourceTypeKind                  = $resourceTypeKind
                DiagnosticSettingName             = $diag.name
                HasDiagnosticSettings             = $true
                MissingCategories                 = ($requiredCategories -join ', ')
                EnabledCategories                 = ($diag.properties.logs.category -join ', ')
                IsEvalDataExist                   = $true
                EnabledCategoryCount              = $diag.properties.logs.category.Count
                EnabledRequiredCategoryCount      = $enabledRequiredCategories.Count
                RequiredCategoryCount             = $requiredCategories.Count
                HasAllRequiredCategoriesEnabled   = ($enabledRequiredCategories.Count -eq $requiredCategories.Count)
                HasOnlyRequiredCategoriesEnabled  = ($diag.properties.logs.category.Count -eq $requiredCategories.Count) -and ($enabledRequiredCategories.Count -eq $requiredCategories.Count)
                ResHasLogCategorySettings         = $hasLogCategorySettings
                ResSupportsDiagnosticSettings     = $supportsDiagnosticSettings
            }
            $output += $statusObject
        }
    }

    return $output
}
