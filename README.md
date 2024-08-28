# Azure Network Analysis Tool

This PowerShell script exports and analyzes Azure network data to identify potential discrepancies in routing configurations.

## Features

- Exports Virtual Network and Route Table data from Azure subscriptions
- Analyzes routes to identify those not matching any Virtual Network address space
- Supports filtering by region and excluding specific IP ranges
- Outputs results to a CSV file for easy review

## Prerequisites

- PowerShell 5.1 or later
- Azure PowerShell module (`Az`)
- Azure account with appropriate permissions to read network configurations

## Usage

1. Clone or download this repository to your local machine.

2. Open PowerShell and navigate to the script directory.

3. Run the script with desired parameters:

```powershell
.\AzureNetworkAnalysis.ps1 -rootDirectory "C:\AzureData" -specificRouteTableName "MyRouteTable" -desiredRegion "EastUS" -excludedIPRanges @("10.0.0.0/8", "172.16.0.0/12")
```

### Parameters

- `rootDirectory`: Directory for storing exported data and results (default: "/Users/ender/Downloads/testexportroutes")
- `specificRouteTableName`: Name of a specific route table to analyze (optional)
- `desiredRegion`: Azure region to filter results (optional)
- `excludedIPRanges`: Array of IP ranges to exclude from analysis (optional)

## Output

The script generates a CSV file named `discrepancies.csv` in the root directory, containing routes that don't match any Virtual Network address space.

## Contributing

Contributions to improve the script are welcome. Please submit a pull request or open an issue to discuss proposed changes.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
