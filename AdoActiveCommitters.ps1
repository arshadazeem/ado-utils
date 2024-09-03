# PowerShell script to get the number of unique committers in ADO

#Base64-encodes the Personal Access Token (PAT)
$pat = "YOUR_PAT_HERE"
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($pat)"))
 
# Function to get all projects
function Get-Projects {
    $url = "https://dev.azure.com/YOUR_ADO_ORG_HERE/_apis/projects?api-version=6.0"
    Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
}
 
# Function to get all repos in a project
function Get-Repos($projectId) {
    $url = "https://dev.azure.com/YOUR_ADO_ORG_HERE/$projectId/_apis/git/repositories?api-version=6.0"
    Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}
}
 
# Function to get all commits in a repo from the last 90 days
function Get-Commits($projectName, $repoId) {

    # This is a weird hack for now to get this working
    # TODO: Troubleshoot this
    $localProjectName = $projectName[0]
    $localRepoId = $projectName[1]

    $date90DaysAgo = (Get-Date).AddDays(-90).ToString("yyyy-MM-ddTHH:mm:ssZ")
    $url = "https://dev.azure.com/YOUR_ADO_ORG_HERE/$localProjectName/_apis/git/repositories/$localRepoId/commits?searchCriteria.fromDate=$date90DaysAgo&api-version=6.0"
    Invoke-RestMethod -Uri $url -Method Get -Headers @{Authorization=("Basic {0}" -f $base64AuthInfo)}

}
 
# Initialize a hashtable to store unique committers
$uniqueCommitters = @{}
 
# Iterate through all projects
$projects = Get-Projects

#Write-Host "projects are: $projects"

foreach ($project in $projects.value) {
    # Iterate through all repos in the current project
    $repos = Get-Repos($project.id)
    foreach ($repo in $repos.value) {
        # Iterate through all commits in the current repo from the last 90 days

      #  Write-Host "repoId is: $project.name"  

      $ProjectName = $project.name
      $RepoId = $repo.id

        $commits = Get-Commits($ProjectName, $RepoId)
        foreach ($commit in $commits.value) {
            # Add the committer to the hashtable if not already present
            if (-not $uniqueCommitters.ContainsKey($commit.committer.email)) {
                $uniqueCommitters[$commit.committer.email] = $commit.committer.name
            }
        }
    }
}
 
Write-Output "Unique committers in the last 90 days:" 
# Output the names of each unique committer
$uniqueCommitters.Values | Sort-Object | Get-Unique
 
# Output the total count of unique committers
$uniqueCommitters.Count