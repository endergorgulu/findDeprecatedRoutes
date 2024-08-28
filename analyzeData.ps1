# Specify the base directory
$baseDirectory = "/Users/ender/Downloads/testexportroutes"  # Update this with your base directory

# Define the subdirectories based on the base directory
$vnetJsonDir = Join-Path -Path $baseDirectory -ChildPath "vnets"
$routeTableJsonDir = Join-Path -Path $baseDirectory -ChildPath "routes"
$csvPath = Join-Path -Path $baseDirectory -ChildPath "discrepancies.csv"

# Define the region you want to filter by (leave blank for all)
$desiredRegion = ""  # Leave blank or specify a region

# Define IP ranges to exclude (leave blank for none)
$excludedIPRanges = @()  # Leave blank or specify ranges to exclude

# Function to parse VNet JSON and extract relevant data
function Parse-VNetJson {
    Param ($filePath)
    try {
        $vnetData = Get-Content $filePath | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "Error parsing VNet JSON file: $filePath"
        return @()
    }

    $vnetInfo = @()
    if ([string]::IsNullOrWhiteSpace($desiredRegion) -or $vnetData.Location -eq $desiredRegion) {
        foreach ($subnet in $vnetData.Subnets) {
            $addressSpace = $vnetData.AddressSpace.AddressPrefixes -join ", "
            $subnetAddressPrefix = $subnet.AddressPrefix -join ", "  # Ensure it's a string
            $vnetInfo += [PSCustomObject]@{
                VNetName = $vnetData.Name
                AddressSpace = $addressSpace
                SubnetName = $subnet.Name
                SubnetAddressPrefix = $subnetAddressPrefix
                Location = $vnetData.Location
            }
        }
    }
    return $vnetInfo
}

# Function to parse Route Table JSON and extract relevant data
function Parse-RouteTableJson {
    Param ($filePath)
    try {
        $routeTableData = Get-Content $filePath | ConvertFrom-Json -ErrorAction Stop
    } catch {
        Write-Error "Error parsing Route Table JSON file: $filePath"
        return @()
    }

    $routeInfo = @()
    if ([string]::IsNullOrWhiteSpace($desiredRegion) -or $routeTableData.Location -eq $desiredRegion) {
        foreach ($route in $routeTableData.Routes) {
            if (-not ($route.AddressPrefix -match "[a-zA-Z]") -and
                ([string]::IsNullOrWhiteSpace($excludedIPRanges) -or $excludedIPRanges -notcontains $route.AddressPrefix)) {
                $routeInfo += [PSCustomObject]@{
                    RouteTableName = $routeTableData.Name
                    RouteName = $route.Name  # Add this line to capture the route name
                    AddressPrefix = $route.AddressPrefix
                    Location = $routeTableData.Location
                }
            }
        }
    }
    return $routeInfo
}


# Check if JSON files exist in the directories
if ((Get-ChildItem $vnetJsonDir -Filter "*.json").Count -eq 0) {
    Write-Host "No JSON files found in $vnetJsonDir. Aborting script."
    return
}
if ((Get-ChildItem $routeTableJsonDir -Filter "*.json").Count -eq 0) {
    Write-Host "No JSON files found in $routeTableJsonDir. Aborting script."
    return
}

# Read and parse all VNet and Route Table JSON files
$vnetInfo = Get-ChildItem $vnetJsonDir -Filter "*.json" | ForEach-Object { Parse-VNetJson $_.FullName }
$routeTableInfo = Get-ChildItem $routeTableJsonDir -Filter "*.json" | ForEach-Object { Parse-RouteTableJson $_.FullName }

# Compare Route Table Address Prefixes with VNet Address Spaces and Subnets
$discrepancies = @()
foreach ($route in $routeTableInfo) {
    $matchFound = $false
    foreach ($vnet in $vnetInfo) {
        # Split the AddressSpace string into an array of address prefixes
        $vnetAddressSpaces = $vnet.AddressSpace -split ',\s*'
        if (($route.AddressPrefix -in $vnetAddressSpaces) -or ($route.AddressPrefix -eq $vnet.SubnetAddressPrefix)) {
            $matchFound = $true
            break
        }
    }
    if (-not $matchFound) {
        $discrepancies += $route
    }
}


# Convert the discrepancies to a CSV-friendly format by ensuring that all properties are strings
$csvFriendlyDiscrepancies = $discrepancies | ForEach-Object {
    $props = $_.PSObject.Properties
    $outputObj = New-Object -TypeName PSObject
    foreach ($prop in $props) {
        if ($prop.Value -is [Array]) {
            $outputObj | Add-Member -MemberType NoteProperty -Name $prop.Name -Value ($prop.Value -join ", ")
        } else {
            $outputObj | Add-Member -MemberType NoteProperty -Name $prop.Name -Value $prop.Value
        }
    }
    return $outputObj
}

# Export the CSV-friendly discrepancies to a CSV file
$csvFriendlyDiscrepancies | Export-Csv -Path $csvPath -NoTypeInformation
Write-Host "Discrepancies exported to $csvPath"