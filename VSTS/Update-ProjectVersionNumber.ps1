# This script is intended to be used for PowerShell script tasks in VSTS in "inline mode" 

# START OF VALUES TO BE SET BY THE USER
$valueName = 'ProjectBuildNumber'
$token = 'PASTE YOUR PAT TOKEN HERE'
# END OF VALUES TO BE SET BY THE USER

$uriRoot = $env:SYSTEM_TEAMFOUNDATIONSERVERURI
$ProjectName = $env:SYSTEM_TEAMPROJECT
$ProjectId = $env:SYSTEM_TEAMPROJECTID 
$uri = "$uriRoot$ProjectName/_apis/build/definitions?api-version=2.0"

# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f "", $token)))
$header = @{Authorization = ("Basic {0}" -f $base64AuthInfo)}

# Get the list of Build Definitions
$buildDefs = Invoke-RestMethod -Uri $uri -Method Get -ContentType "application/json" -Headers $header
 
# Find the build definition for this project
$buildDef = $buildDefs.value | Where-Object { $_.Project.id -eq $ProjectId }

if ($buildDef -eq $null)
{
    Write-Error "Unable to find a build definition for Project '$ProjectName'. Check the config values and try again." -ErrorAction Stop
}
# NOTE: ensure we call the v 2.0 api! (both get and put calls NEED the same api versions!)
# get its details
$projectDef = Invoke-RestMethod -Uri "$($buildDef.Url)?api-version=2.0" -Method Get -ContentType "application/json" -Headers $header

if ($projectDef.variables.$valueName -eq $null)
{
    Write-Error "Unable to find a variable called '$valueName' in Project $ProjectName. Please check the config and try again." -ErrorAction Stop
}
# get and increment the variable in $valueName
[int]$counter = [convert]::ToInt32($projectDef.variables.$valueName.Value, 10)
$updatedCounter = $counter + 1
Write-Host "Project Build Number for '$ProjectName' is $counter. Will be updating to $updatedCounter"

# Update the value and update VSTS
$projectDef.variables.ProjectBuildNumber.Value = $updatedCounter.ToString()
$projectDefJson = $projectDef | ConvertTo-Json -Depth 50 -Compress
Invoke-RestMethod -Method Put -Uri "$($projectDef.Url)?api-version=2.0" -Headers $header -ContentType "application/json" -Body $projectDefJson | Out-Null

