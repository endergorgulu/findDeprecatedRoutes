# Log in to Azure
Connect-AzAccount

# Get all subscriptions
$subscriptions = Get-AzSubscription

# Define the root directory where the folders will be created
$rootDirectory = "/Users/ender/Downloads/testexportroutes" # Change this path to your desired location

# Specify a route table name to export (leave blank for all)
$specificRouteTableName = "" # Add the name of the route table here if needed

# Create /routes/ and /vnets/ directories if they do not exist
$routesDirectory = Join-Path -Path $rootDirectory -ChildPath "routes"
$vnetsDirectory = Join-Path -Path $rootDirectory -ChildPath "vnets"
New-Item -ItemType Directory -Path $routesDirectory -Force
New-Item -ItemType Directory -Path $vnetsDirectory -Force

# Initialize flag to track if the route table is found
$routeTableFound = $false

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    # Set the context to the current subscription
    Set-AzContext -SubscriptionId $subscription.Id

    # Export all virtual networks
    $vnets = Get-AzVirtualNetwork | Select-Object Name, AddressSpace, Subnets, VirtualNetworkPeerings
    $vnetJson = $vnets | ConvertTo-Json -Depth 5
    $vnetFileName = Join-Path -Path $vnetsDirectory -ChildPath ("vnet-details-" + $subscription.Id + ".json")
    Out-File -FilePath $vnetFileName -InputObject $vnetJson -Encoding UTF8

    # Check for specific route table in the current subscription
    if (![string]::IsNullOrWhiteSpace($specificRouteTableName)) {
        $routeTable = Get-AzRouteTable | Where-Object {$_.Name -eq $specificRouteTableName}
        if ($routeTable -ne $null) {
            $routeTableFound = $true
            $routeJson = $routeTable | Select-Object Name, Location, Routes, Subnets | ConvertTo-Json -Depth 5
            $routeFileName = Join-Path -Path $routesDirectory -ChildPath ("route-tables-" + $subscription.Id + ".json")
            Out-File -FilePath $routeFileName -InputObject $routeJson -Encoding UTF8
        }
    } else {
        # Export all route tables
        $routeTables = Get-AzRouteTable | Select-Object Name, Location, Routes, Subnets
        $routeJson = $routeTables | ConvertTo-Json -Depth 5
        $routeFileName = Join-Path -Path $routesDirectory -ChildPath ("route-tables-" + $subscription.Id + ".json")
        Out-File -FilePath $routeFileName -InputObject $routeJson -Encoding UTF8
    }
}

# Check if the route table was found when a specific route table was requested
if (![string]::IsNullOrWhiteSpace($specificRouteTableName) -and -not $routeTableFound) {
    Write-Host "Error: Route table '$specificRouteTableName' not found in any subscription. No data exported."
    Remove-Item -Path $routesDirectory -Recurse -Force
    Remove-Item -Path $vnetsDirectory -Recurse -Force
} else {
    Write-Host "Data exported to $vnetsDirectory and $routesDirectory"
}
