<#
.SYNOPSIS
Downloads all attachments from an Azure DevOps bug work item.

.DESCRIPTION
Given an organization, project, bug ID and personal access token (PAT), this
script downloads all files attached to the specified bug work item. If no
organization, project or bug ID are provided, the script defaults to the bug
at https://dev.azure.com/KornitDigital/Kornit_PD/_workitems/edit/167787.

.PARAMETER Organization
Azure DevOps organization name. Defaults to 'KornitDigital'.

.PARAMETER Project
Azure DevOps project name. Defaults to 'Kornit_PD'.

.PARAMETER BugId
ID of the bug work item. Defaults to 167787.

.PARAMETER Pat
Personal access token with access to work item attachments.

.PARAMETER OutputDirectory
Directory where attachments will be saved. Defaults to the current
working directory.

.EXAMPLE
./download-bug-attachments.ps1 -Pat "<PAT>" -OutputDirectory "./files"
#>
param(
    [string]$Organization = 'KornitDigital',

    [string]$Project = 'Kornit_PD',

    [int]$BugId = 167787,

    [Parameter(Mandatory=$true)]
    [string]$Pat,

    [string]$OutputDirectory = '.'
)

if (-not (Test-Path $OutputDirectory)) {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":" + $Pat))
$headers = @{ Authorization = "Basic $base64AuthInfo" }

$workItemUri = "https://dev.azure.com/$Organization/$Project/_apis/wit/workitems/$BugId?`$expand=relations&api-version=7.0"
$workItem = Invoke-RestMethod -Uri $workItemUri -Headers $headers -Method Get

foreach ($relation in $workItem.relations) {
    if ($relation.rel -eq "AttachedFile") {
        $fileName = $relation.attributes.name
        $attachmentUrl = "$($relation.url)?api-version=7.0"
        $outputPath = Join-Path $OutputDirectory $fileName
        Write-Host "Downloading $fileName"
        Invoke-RestMethod -Uri $attachmentUrl -Headers $headers -OutFile $outputPath -Method Get
    }
}


