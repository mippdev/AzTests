function Get-DiagnosticSettingsStatus {
    param (
        [Hashtable]$resourceEval,
        [Object]$resourceData
    )

    $output = @()

    foreach ($resource in $resourceData) {
        $resourceTypeKind = "$($resource.res.Type)|$($resource.res.Kind)"
        $evalData = $resourceEval[$resourceTypeKind]

        $diagnosticSettings = $resource.diag | ConvertFrom-Json

        foreach ($diag in $diagnosticSettings) {
            $statusObject = New-Object PSObject -Property @{
                SubscriptionID                    = $resource.subid
                SubscriptionDisplayName           = $resource.sub.DisplayName
                ResourceTypeKind                  = $resourceTypeKind
                ResourceId                        = $resource.id
                ResourceLocation                  = $resource.res.Location
                ResourceType                      = $resource.res.Type
                ResourceKind                      = $resource.res.Kind
                ResourceGroupName                 = $resource.res.ResourceGroupName
                DiagnosticSettingName             = $diag.name
                StorageAccountId                  = $diag.storageAccountId
                LogAnalyticsWorkspaceId           = $diag.workspaceId
                EventHubAuthorizationRuleId       = $diag.eventHubAuthorizationRuleId
                EventHubNamespace                 = if ($diag.eventHubAuthorizationRuleId -match ".+/namespaces/([^/]+)/") { $matches[1] } else { $null }
                EventHubNamespaceSubscription     = if ($diag.eventHubAuthorizationRuleId -match ".+/subscriptions/([^/]+)/") { $matches[1] } else { $null }
                EventHub                          = $diag.eventHubName
                
                IsEvalDataExist                   = ($null -ne $evalData)
                HasDiagnosticSettings             = ($null -ne $diag)
                EnabledCategories                 = $diag.log | ForEach-Object { $_.category }
                EnabledCategoryCount              = ($diag.log | ForEach-Object { $_.category }).Count

                MissingCategories                 = if ($null -ne $evalData) { $evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] -and ($_ -notin $diag.log | ForEach-Object { $_.category }) } } else { @() }
                RequiredCategoryCount             = if ($null -ne $evalData) { ($evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] }).Count } else { 0 }
                EnabledRequiredCategoryCount      = if ($null -ne $evalData) { ($diag.log | ForEach-Object { $_.category } | Where-Object { $_ -in $evalData.LogCategories.Keys | Where-Object { $evalData.LogCategories[$_] } }).Count } else { 0 }
                HasAllRequiredCategoriesEnabled   = if ($null -ne $evalData) { $EnabledRequiredCategoryCount -eq $RequiredCategoryCount } else { $false }
                HasOnlyRequiredCategoriesEnabled  = if ($null -ne $evalData) { ($diag.log | ForEach-Object { $_.category }).Count -eq $RequiredCategoryCount -and $HasAllRequiredCategoriesEnabled } else { $false }
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
