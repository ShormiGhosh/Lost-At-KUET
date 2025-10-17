<#
split_merges_to_independent_branches.ps1

For each merge commit on a source branch (default: sadia), creates a new branch
based on a specified base (default: main) and cherry-picks the commits that were
introduced by the merged branch onto that base. This results in branches that
contain the same feature commits but are not children of `sadia` (they are
independent branches based on the chosen base).

Usage (PowerShell):
  pwsh ./scripts/split_merges_to_independent_branches.ps1 -SourceBranch sadia -BaseBranch main -Prefix feature/ -DryRun

Options:
  -SourceBranch <string> : branch to scan for merges (default: sadia)
  -BaseBranch <string>   : branch to base new branches on (default: main)
  -Prefix <string>       : prefix for created branch names (default: merged/)
  -Push                  : push created branches to origin
  -DryRun                : show actions without making changes

Notes & caveats:
- This script will create NEW commits on the new branches (cherry-picks). The
  new commits will have new SHAs but the script will set the author and
  committer dates to the original values so timestamps match the originals.
- Conflicts may occur during cherry-pick. The script will stop on conflict for
  that branch; you must resolve conflicts manually and continue.
- The script does NOT modify `sadia` or any other branch; it only creates new
  branches. It is safe to run after reviewing the DryRun output.
#>
param(
  [string]$SourceBranch = 'sadia',
  [string]$BaseBranch = 'main',
  [string]$Prefix = 'feature/',
  [switch]$Push,
  [switch]$DryRun
)

function Run-Git([string]$args) {
  $out = git $args 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "git $args failed: $out"
  }
  return $out
}

# Ensure git repository
try { Run-Git 'rev-parse --git-dir' | Out-Null } catch { throw 'Not a git repo or git not installed' }

Write-Host "Fetching remote refs..."
if (-not $DryRun) { Run-Git 'fetch --all --prune' | Out-Null }

# Get merge commits on source branch
$mergeLines = Run-Git "log $SourceBranch --merges --pretty=format:'%H%x09%P%x09%ad%x09%s' --date=iso" -split "`n" | Where-Object { $_ -ne '' }
if ($mergeLines.Count -eq 0) { Write-Host "No merge commits on $SourceBranch"; exit 0 }

foreach ($line in $mergeLines) {
  $parts = $line -split "\t"
  $mergeHash = $parts[0]
  $parents = $parts[1].Split(' ')
  if ($parents.Count -lt 2) { Write-Host "Skip ${mergeHash}: not a two-parent merge"; continue }
  $p1 = $parents[0]  # often the branch into which the merge was made (sadia before merge)
  $p2 = $parents[1]  # tip of merged branch
  Write-Host "Processing merge $mergeHash (parents: $p1, $p2)"

  # Determine commits that were on the merged branch but not on p1 (the feature commits)
  $commits = Run-Git "rev-list --reverse $p2 ^$p1" -split "`n" | Where-Object { $_ -ne '' }
  if ($commits.Count -eq 0) { Write-Host "No distinct commits found for merged branch (p2:$p2 vs p1:$p1), skipping"; continue }

  # Derive a branch name from merge subject or fallback to short sha
  if ($parts.Count -ge 4) { $subject = $parts[3] } else { $subject = '' }
  $bn = $null
  if ($subject -match "Merge branch '\'(?<b>[^']+)\'") { $bn = $matches['b'] }
  elseif ($subject -match "from\s+(?:.+\/)?(?<b>[A-Za-z0-9_\-\/]+)") { $bn = $matches['b'] }
  if ($bn -and $bn -match '^[^/]+\/(.+)$') { $bn = $matches[1] }
  if (-not $bn) { $bn = "$Prefix$($p2.Substring(0,7))" }
  $safeBn = $bn -replace '[^a-zA-Z0-9_\-\/]', '-' -replace '-{2,}', '-' -replace '^\-+|\-+$', ''
  if ($safeBn.Length -gt 50) { $safeBn = $safeBn.Substring(0,50) }
  # ensure prefix
  if ($safeBn -notlike "$Prefix*") { $branchName = "$Prefix$safeBn" } else { $branchName = $safeBn }

  Write-Host "Will create independent branch: $branchName based on $BaseBranch with commits from $p2"
  if ($DryRun) { continue }

  # create new branch from base
  Run-Git "checkout $BaseBranch"
  Run-Git "checkout -b $branchName"

  # Cherry-pick each commit in order, preserving author/committer dates
  $conflict = $false
  foreach ($c in $commits) {
    Write-Host "Cherry-picking $c"
    # Get metadata
    $author = (Run-Git "show -s --format='%an <%ae>' $c").Trim()
    $authorDate = (Run-Git "show -s --format='%aI' $c").Trim()
    $committerDate = (Run-Git "show -s --format='%cI' $c").Trim()
    $message = (Run-Git "show -s --format=%B $c")

    # Apply changes without committing
    $res = git cherry-pick --no-commit $c 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Conflict while cherry-picking $c. Resolve conflicts manually in branch $branchName, then run 'git cherry-pick --continue'."
      $conflict = $true
      break
    }

    # Set env vars for preserving dates
    $env:GIT_AUTHOR_DATE = $authorDate
    $env:GIT_COMMITTER_DATE = $committerDate

    # Commit with original author and message
    git commit --author="$author" --date="$authorDate" -m "$( $message.TrimEnd() )"
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to commit cherry-picked $c"
    }

    Remove-Item Env:GIT_AUTHOR_DATE -ErrorAction SilentlyContinue
    Remove-Item Env:GIT_COMMITTER_DATE -ErrorAction SilentlyContinue
  }

  if ($conflict) {
    Write-Host "Branch $branchName created but cherry-pick stopped due to conflicts. Resolve them, then run: git cherry-pick --continue"
    continue
  }

  Write-Host "Successfully created $branchName with $($commits.Count) commits"
  if ($Push) {
    Run-Git "push -u origin $branchName"
    Write-Host "Pushed $branchName to origin"
  }
}

Write-Host "All done."