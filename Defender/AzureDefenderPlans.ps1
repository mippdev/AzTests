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
    $defenderPlans = Get-AzSecurityPricing

    # Get the Azure RateCard pricing details for the subscription
    $rateCard = Get-AzRateCard -Currency "USD" -Locale "en-US" -Region "US"

    # Loop through each Defender plan
    foreach ($plan in $defenderPlans) {
        # Find the matching meterId in the rate card
        $matchingMeter = $rateCard.Meters | Where-Object { $_.MeterId -eq $plan.PricingTier }

        # Calculate the cost based on the meter rates
        $cost = 0
        if ($matchingMeter -ne $null) {
            $cost = $matchingMeter.MeterRates["0"]
        }

        # Calculate price to enable for all resources
        $priceToEnable = $cost * $plan.ResourceCount

        # Create a custom object with the required columns
        $result = [PSCustomObject]@{
            SubscriptionName   = $subscription.Name
            DefenderPlanName   = $plan.Name
            DefenderPlanStatus = if ($plan.FreeTier) { "Off" } else { "On" }
            DefenderPlanPricing = $cost
            ResourceQuantity   = $plan.ResourceCount
            MonitoringCoverage = $plan.MonitoringCoverage
            PriceToEnable      = $priceToEnable
        }

        # Add the result to the results array
        $results += $result
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "AzureDefenderPlans.csv" -NoTypeInformation
