# Login to your Azure account
Connect-AzAccount

# Get all subscriptions in your tenant
$subscriptions = Get-AzSubscription

# Initialize an empty array to store the exemptions with parsed data
$exemptionsWithParsedData = @()

foreach ($subscription in $subscriptions) {
    # Set the current subscription context
    Set-AzContext -Subscription $subscription.Id

    # Get policy exemptions for the current subscription
    $exemptions = Get-AzPolicyExemption -Descendants

    foreach ($exemption in $exemptions) {
        # Parse the ResourceId
        $resourceIdParts = $exemption.ResourceId.Split('/')
        $subscriptionName = $resourceIdParts[2]
        $resourceGroupName = $resourceIdParts[4]
        $resourceType = "$($resourceIdParts[6])/$($resourceIdParts[7])"

        # Add the parsed data to the exemption object
        $exemption = New-Object PSObject  
        $exemption | Add-Member -NotePropertyName "SubscriptionName" -NotePropertyValue $subscriptionName
        $exemption | Add-Member -NotePropertyName "ResourceGroupName" -NotePropertyValue $resourceGroupName
        $exemption | Add-Member -NotePropertyName "ResourceType" -NotePropertyValue $resourceType

        # Append the exemption with parsed data to the array
        $exemptionsWithParsedData += $exemption
    }
}

# Output the exemptions with parsed data
$exemptionsWithParsedData | Format-Table -Property Name, SubscriptionName, ResourceGroupName, ResourceType, ExemptionCategory
