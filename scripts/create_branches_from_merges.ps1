<#
create_branches_from_merges.ps1

Scans merge commits on the current branch (default: sadia) and creates a local branch
for each merged branch by inspecting the second parent of each merge commit.

Usage (PowerShell):
  # from repo root
  pwsh ./scripts/create_branches_from_merges.ps1 -Branch sadia -Push:$false

Options:
  -Branch <string>   : branch to scan for merge commits (default: sadia)
  -Push              : switch to push created branches to origin
  -Prefix <string>   : prefix for created branch names (default: merged/)
  -DryRun            : show actions without creating branches

Notes:
- This script does NOT rewrite history. It creates branch refs that point to the
  second parent commit of merge commits. That second parent is usually the tip
  of the merged branch (depends on your merge strategy).
- If the second parent points to a commit that already has a branch name, the
  script will skip or optionally reuse that existing name.
- Created branches preserve the original commit timestamps because they are
  not new commits — they are just refs to existing commits.
#>
param(
  [string]$Branch = 'sadia',
  [switch]$Push,
  [string]$Prefix = 'merged/',
  [switch]$DryRun
)

function Run-Git([string]$args) {
  $out = git $args 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw "git $args failed: $out"
  }
  return $out
}

# Ensure we're in a git repo
try { Run-Git 'rev-parse --git-dir' | Out-Null } catch { throw 'Not a git repo or git not installed' }

# Fetch remote refs to ensure parent commits are available locally
Write-Host "Fetching remote refs..."
if (-not $DryRun) { Run-Git 'fetch --all --prune' | Out-Null }

# Get merge commits on the target branch
$mergeCommitsRaw = Run-Git "log $Branch --merges --pretty=format:'%H%x09%P%x09%ad%x09%s' --date=iso"
$lines = $mergeCommitsRaw -split "`n" | Where-Object { $_ -ne '' }

if ($lines.Count -eq 0) { Write-Host "No merge commits found on branch $Branch"; exit 0 }

foreach ($line in $lines) {
  # format: commitHash\tparentHashes\tdate\tsubject
  $parts = $line -split "\t"
  if ($parts.Count -lt 2) { continue }
  $mergeHash = $parts[0]
  $parentHashes = $parts[1].Split(' ')
  if ($parentHashes.Count -lt 2) { Write-Host "Merge $mergeHash does not have two parents? skipping"; continue }
  $secondParent = $parentHashes[1]

  # Derive a branch name: prefer an existing ref that points at the second parent.
  $existingRefsRaw = git for-each-ref --format='%(refname:short) %(objectname)'
  $existingRefs = $existingRefsRaw -split "`n" | Where-Object { $_ -match $secondParent }
  $branchName = $null
  if ($existingRefs -and $existingRefs.Count -gt 0) {
    # pick the first ref that points exactly to the second parent
    $branchName = ($existingRefs[0] -split ' ')[0]
  } else {
    # Try to extract a likely source branch name from common merge commit messages.
    $subject = ($parts.Count -ge 4) ? $parts[3] : ''
    $bn = $null
    # Pattern: Merge branch 'feature/xyz'
    if ($subject -match "Merge branch '\'(?<b>[^']+)\'") { $bn = $matches['b'] }
    # Pattern: Merge remote-tracking branch 'origin/feature/xyz'
    elseif ($subject -match "Merge remote-tracking branch '\'(?<b>[^']+)\'") { $bn = $matches['b'] }
    # Pattern: Merge pull request #123 from owner/feature/xyz
    elseif ($subject -match "from\s+(?:.+\/)?(?<b>[A-Za-z0-9_\-\/]+)") { $bn = $matches['b'] }

    # If we captured a remote-qualified name like origin/feature/x, strip the remote prefix
    if ($bn -and $bn -match '^[^/]+\/(.+)$') { $bn = $matches[1] }

    # Sanitize candidate branch name
    if ($bn) {
      $safeBn = $bn -replace '[^a-zA-Z0-9_\-\/]', '-' -replace '-{2,}', '-' -replace '^\-+|\-+$', ''
      # Prevent creating branches that collide with protected names
      $protected = @('main','master','sadia','develop','dev')
      $baseName = $safeBn
      if ($protected -contains $baseName) { $baseName = "$Prefix$baseName" }
      # Limit length
      if ($baseName.Length -gt 50) { $baseName = $baseName.Substring(0,50) }
      $branchName = $baseName
    } else {
      # fallback: use the merge subject and commit short sha
      $safeSubject = $subject -replace '[^a-zA-Z0-9_\-]', '-' -replace '-{2,}', '-' -replace '^\-+|\-+$', ''
      if ($safeSubject.Length -gt 30) { $safeSubject = $safeSubject.Substring(0,30) }
      $branchName = "$Prefix$($safeSubject)-$($secondParent.Substring(0,7))"
    }
  }

  # Final safety: do not accidentally create a branch that equals the current branch or protected branches
  $protectedFinal = @('main','master','sadia','develop','dev')
  if ($protectedFinal -contains $branchName) { $branchName = "$Prefix$branchName" }

  Write-Host "Merge $mergeHash -> second parent $secondParent -> branch $branchName"
  if ($DryRun) { continue }

  # Create local branch if it doesn't exist
  $exists = (git rev-parse --verify --quiet $branchName) -ne $null
  if (-not $exists) {
    Run-Git "branch $branchName $secondParent"
    Write-Host "Created branch $branchName -> $secondParent"
  } else {
    Write-Host "Branch $branchName already exists, skipping creation"
  }

  if ($Push) {
    Run-Git "push -u origin $branchName"
    Write-Host "Pushed $branchName to origin"
  }
}

Write-Host 'Done.'
