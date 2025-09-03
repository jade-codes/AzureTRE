Param(
    [Parameter(Mandatory = $true)]
    [string]$RequiredWorkItemType = $env:REQUIRED_WORK_ITEM_TYPE,

    [Parameter(Mandatory = $true)]
    [string]$RequiredParentType = $env:REQUIRED_PARENT_TYPE,

    [Parameter(Mandatory = $true)]
    [string]$OrganizationUrl = $env:ORGANIZATION_URL,

    [Parameter(Mandatory = $true)]
    [string]$ProjectName = $env:PROJECT_NAME,

    [Parameter(Mandatory = $true)]
    [string]$PullRequestId = $env:PULLREQUEST_ID,

    [Parameter(Mandatory = $true)]
    [string]$RepositoryName = $env:BUILD_REPOSITORY_NAME
)

<#
.SYNOPSIS
    Validates linked work items for a pull request in Azure DevOps.

.DESCRIPTION
    This script validates that work items linked to a pull request meet specific requirements,
    such as having the required parent work item type.

.PARAMETER RequiredParentType
    The work item type that is required as a parent for linked work items.
    Can be provided via environment variable REQUIRED_PARENT_TYPE.

.PARAMETER OrganizationUrl
    The URL of the Azure DevOps organization.
    Can be provided via environment variable ORGANIZATION_URL.

.PARAMETER ProjectName
    The name of the Azure DevOps project.
    Can be provided via environment variable PROJECT_NAME.

.PARAMETER PullRequestId
    The ID of the pull request to validate linked work items for.
    Can be provided via environment variable PULLREQUEST_ID.

.PARAMETER RepositoryName
    The name of the repository where the pull request exists.
    Can be provided via environment variable BUILD_REPOSITORY_NAME.

.EXAMPLE
    .\validate-linked-work-items.ps1 -RequiredParentType "Epic" -OrganizationUrl "https://dev.azure.com/myorg" -ProjectName "MyProject" -PullRequestId "123" -RepositoryName "MyRepo" -AccessToken "token123"

.NOTES
    All parameters are mandatory and can be provided either directly or through environment variables.

 .SYNOPSIS
    Validates that linked PR work items of a given type have a parent of the required type.

 .NOTES
  Emits Azure DevOps logging commands for success / failure.
#>

$config = [pscustomobject]@{
    RequiredWorkItemType = $RequiredWorkItemType
    RequiredParentType   = $RequiredParentType
    OrganizationUrl      = $OrganizationUrl
    ProjectName          = $ProjectName
    PullRequestId        = $PullRequestId
    RepositoryName       = $RepositoryName
}

function Write-Section($message) {
    Write-Host "##[section]$message"
}

function Write-ErrorLog($message) {
    Write-Host "##vso[task.logissue type=error]$message"
}

function Write-WarningLog($message) {
    Write-Host "##[warning]$message"
}

function Complete-Failed {
    Write-Host "##vso[task.complete result=Failed;]"
    exit 0
}

function Get-AuthHeaders($token) {
    if ([string]::IsNullOrWhiteSpace($token)) {
        Write-ErrorLog 'Missing access token'
        exit 1
    }
    $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$token"))
    return @{ Authorization = "Basic $b64" }
}

function Invoke-AdoGet($url, $headers) {
    try {
        return Invoke-RestMethod -Uri $url -Headers $headers -Method Get -ErrorAction Stop
    }
    catch {
        Write-ErrorLog "Request failed: $url"
        throw
    }
}

function Get-PullRequestWorkItems($config, $headers) {
    $url = "$($config.OrganizationUrl)/$($config.ProjectName)/_apis/git/repositories/$($config.RepositoryName)/pullRequests/$($config.PullRequestId)/workitems?api-version=7.1"
    (Invoke-AdoGet -url $url -headers $headers).value
}

function Get-WorkItem($config, $headers, $id, [switch]$expandRelations) {
    $expand = $expandRelations.IsPresent ? '?$expand=relations&api-version=7.1' : '?api-version=7.1'
    $url = "$($config.OrganizationUrl)/$($config.ProjectName)/_apis/wit/workitems/$id$expand"
    Invoke-AdoGet -url $url -headers $headers
}

function Test-WorkItems($config, $headers) {

    $errors = New-Object System.Collections.Generic.List[string]

    # Get linked work items for the PR.
    $allLinkedWorkItems = Get-PullRequestWorkItems -config $config -headers $headers

    # Filter linked work items to only those of the required type.
    $linkedWorksItems = $allLinkedWorkItems | Where-Object {
        $workItem = Get-WorkItem -config $config -headers $headers -id $_.id
        $workItem.fields.'System.WorkItemType' -eq $config.RequiredWorkItemType
    }

    # Check if any linked work items of the required type were found.
    if (-not $linkedWorksItems) {
        $errors.Add("There were no work items of type '$($config.RequiredWorkItemType)' linked to the PR.") | Out-Null
        return $errors
    }

    foreach ($linkedWorkItem in $linkedWorksItems) {

        # Get the linked work item details, including relations.
        $workItem = Get-WorkItem -config $config -headers $headers -id $linkedWorkItem.id -expandRelations
        $workItemType = $workItem.fields.'System.WorkItemType'

        # If it is of interest, validate it.
        Write-Section "Validating linked work item with ID '$($workItem.id)' of type '$($workItemType)'."

        # Find the parent work item.
        $parentRel = $workItem.relations | Where-Object { $_.rel -eq 'System.LinkTypes.Hierarchy-Reverse' }
        if (-not $parentRel) {
            $errors.Add("A work item of type '$($config.RequiredWorkItemType)' was found linked to the PR that didn't have a parent.") | Out-Null
            continue
        }

        # Get the parent work item.
        $parentId = $parentRel.url -replace '.*/'
        $parent = Get-WorkItem -config $config -headers $headers -id $parentId

        $parentType = $parent.fields.'System.WorkItemType'

        # Check if the parent type matches the required type.
        if ($parentType -eq $config.RequiredParentType) {
            Write-Host "Valid parent found with ID '$parentId' and type '$parentType'."
            continue
        }

        # Work item parent doesn't match the required type.
        $errors.Add("Work item '$($workItem.id)' was linked to the PR, but it didn't have a parent of type '$($config.RequiredParentType)'. Actual: '$parentType'..") | Out-Null
    }

    return $errors
}

try {

    $accessToken = $env:ACCESS_TOKEN ?? $(throw "The ACCESS_TOKEN environment variable is required to authenticate to the Azure DevOps REST APIs.")
    $headers = Get-AuthHeaders -token $accessToken

    Write-Section 'Starting validation...'
    Write-Host "Linked Work Item Type: $($config.RequiredWorkItemType)"
    Write-Host "Required Parent: $($config.RequiredParentType)"

    $validationErrors = Test-WorkItems -config $config -headers $headers

    if ($validationErrors.Count -gt 0) {
        Write-ErrorLog "Validation failed with $($validationErrors.Count) error(s)."
        foreach ($validationError in $validationErrors) {
            Write-ErrorLog $validationError
        }
        Complete-Failed
    }

    Write-Host '✅ Validation succeeded.'
}
catch {
    Write-ErrorLog "Unexpected error: $($_.Exception.Message)"
    Complete-Failed
}
