#Define Defender Pricing from https://azure.microsoft.com/en-us/pricing/details/defender-for-cloud/
$defenderPricing = @(
    [PSCustomObject]@{
        ResourceType   = "AzureSQL"
        FreeTier       = "Basic coverage"
        StandardTier   = 15
        BillingType    = "Per Resource Monthly"
    },
    [PSCustomObject]@{
        ResourceType   = "AppService"
        FreeTier       = "Basic coverage"
        StandardTier   = 14.60
        BillingType    = "Per Resource Monthly"
    },
    [PSCustomObject]@{
        ResourceType   = "StorageAccounts"
        FreeTier       = "Basic coverage"
        StandardTier   = 9.782
        BillingType    = "Per Resource Monthly"
    },
    [PSCustomObject]@{
        ResourceType   = "KeyVault"
        FreeTier       = "Basic coverage"
        StandardTier   = .02
        BillingType    = "Per 10k transactions"
    }
)
#Define Resource Types for Graph Queries
$resourceTypes = @(
    [PSCustomObject]@{ Name = "SqlServers"; Type = "Microsoft.Sql/servers" },
    [PSCustomObject]@{ Name = "AppServices"; Type = "Microsoft.Web/sites" },
    [PSCustomObject]@{ Name = "KeyVaults"; Type = "Microsoft.KeyVault/vaults" },
    [PSCustomObject]@{ Name = "StorageAccounts"; Type = "Microsoft.Storage/storageAccounts" }
)


# Install the Az module if not already installed
if (-not (Get-Module -ListAvailable -Name Az)) {
    Install-Module -Name Az -Scope CurrentUser -Force
}

# Sign in to your Azure account
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Create an array to store the results
$results = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the active subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Get the available Azure Defender plans for the subscription
    try {
        # Attempt to get the Defender plan information
        $defenderPlans = Get-AzSecurityPricing -ErrorAction Stop

        if ($defenderPlans) {
            # Loop through each Defender plan
            foreach ($plan in $defenderPlans) {

                foreach ($resourceType in $resourceTypes) {
                    #Define Graph Query
                    $graphQuery = "
                    Resources
                    | where type == `"$($resourceType.Type)`"
                    | summarize count()
                    "
                    # Run the Azure Resource Graph query
                    $resourceCount = Invoke-AzResourceGraphQuery -Query $graphQuery
                    # Get Resource Name
                    $resourceName = $resourceType.Name
                }
                # Calculate price to enable for all resources
                $priceToEnable = $cost * $plan.ResourceCount

                # Create a custom object with the required columns
                $result = [PSCustomObject]@{
                    SubscriptionName   = $subscription.Name
                    DefenderPlanName   = $plan.Name
                    DefenderPlanStatus = if ($plan.PricingTier -eq "Free") { "Off" } else { "On" }
                    DefenderPlanPricing = $cost
                    ResourceQuantity   = $plan.ResourceCount
                    MonitoringCoverage = $plan.MonitoringCoverage
                    PriceToEnable      = $priceToEnable
                }

                # Add the result to the results array
                $results += $result
            }
        }
    } catch {
        # Continue to the next subscription if an error occurs
        continue
    }

    
}

# Export the results to a CSV file

# Export the results to a CSV file
$results | Export-Csv -Path "AzureDefenderPlans.csv" -NoTypeInformation
