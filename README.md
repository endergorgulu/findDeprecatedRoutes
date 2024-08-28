
# Find Deprecated Routes in Azure Virtual Networks

This project contains PowerShell scripts for exporting Azure network data and analyzing it for deprecated routes, specifically focusing on ensuring compatibility with virtual networks having multiple address ranges.

## Files

- `exportData.ps1`: Exports Azure network data, including virtual network and routing table information for each subscription, and saves it in JSON format.
- `analyzeData.ps1`: Analyzes the exported network data to identify routes that do not match any address space in the virtual networks, handling multiple address ranges per network.

## How to Use

1. Update the `$rootDirectory` variable in `exportData.ps1` to your desired output location.
2. Execute `exportData.ps1` in PowerShell. This script creates `/vnets/` and `/routes/` directories within `$rootDirectory`. For each Azure subscription, it generates a JSON file with virtual network and routing table information.
3. Run `analyzeData.ps1` in PowerShell. This script reads the JSON files from the `/vnets/` and `/routes/` directories, compares the routes with the virtual network address spaces (including multiple address ranges), and outputs a list of routes that are not covered by any virtual network address space.

## Prerequisites

- PowerShell installed on your machine.
- Azure PowerShell module installed. Install it using `Install-Module -Name Az -AllowClobber -Scope CurrentUser`.
- Access to an Azure account with at least `Read permissions` for network data retrieval.

## Steps in `exportData.ps1`

1. Log in to Azure and retrieve all subscriptions.
2. Define the root directory for output (`$rootDirectory`).
3. Optionally specify a specific route table name for export.
4. Create `/routes/` and `/vnets/` directories if they do not exist.
5. Export virtual network and route table data to JSON files in the respective directories.

## Steps in `analyzeData.ps1`

1. Set the base directory to the location where JSON files are stored.
2. Define subdirectories for virtual networks and route tables.
3. Specify the region to filter by (if needed) and define IP ranges to exclude.
4. Read and parse all virtual network and route table JSON files.
5. Compare each route with virtual network address spaces, handling multiple address ranges.
6. Output the discrepancies to a CSV file.
