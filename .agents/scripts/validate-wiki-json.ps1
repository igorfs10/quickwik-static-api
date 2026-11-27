param(
  [string]$GameId = ''
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$mPath = Join-Path $root 'games_manifest.json'
$gamesDir = Join-Path $root 'games'

$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Err([string]$msg) { $script:errors.Add($msg) }
function Add-Warn([string]$msg) { $script:warnings.Add($msg) }

if (-not (Test-Path $mPath)) {
  Add-Err 'games_manifest.json not found at repository root.'
  $manifest = $null
} else {
  try {
    $manifest = Get-Content $mPath -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Add-Err ("Invalid JSON in games_manifest.json: " + $_.Exception.Message)
    $manifest = $null
  }
}

$isoRegex = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
$reqRootKeys = @('id', 'title', 'icon', 'updated_at', 'sources', 'process_keywords', 'categories', 'entries')
$forbiddenRootKeys = @('game_id', 'name', 'version')
$validTypes = @('text', 'image', 'youtube', 'video', 'yt')
$validColors = @('cyan', 'blue', 'gray', 'yellow', 'orange', 'green', 'red', 'purple', 'pink')
$forbiddenGlossary = '\b(API|JSON|Manifesto|Payload|Schema|(?<!Weapons\s)Cache|PID|Bin' + [char]0x00E1 + 'rio)\b'

$manifestById = @{}

if ($null -ne $manifest) {
  if (-not $manifest.updated_at -or ($manifest.updated_at -notmatch $isoRegex)) {
    Add-Err "games_manifest.json root updated_at invalid: '$($manifest.updated_at)' (expected ISO-8601 UTC ending with Z)"
  }
  if (-not $manifest.games -or $manifest.games.Count -eq 0) {
    Add-Err 'games_manifest.json games array is empty or missing.'
  } else {
    $seenManifestIds = New-Object 'System.Collections.Generic.HashSet[string]'
    foreach ($mg in $manifest.games) {
      $gid = [string]$mg.id
      if ([string]::IsNullOrWhiteSpace($gid) -or $gid -notmatch '^[a-z0-9_]+$') {
        Add-Err "Manifest entry has invalid snake_case id: '$gid'"
        continue
      }
      if (-not $seenManifestIds.Add($gid)) {
        Add-Err "Duplicate id in games_manifest.json: '$gid'"
      }
      if ([string]::IsNullOrWhiteSpace($mg.title)) { Add-Err "Manifest entry '$gid' missing title" }
      if ([string]::IsNullOrWhiteSpace($mg.icon)) { Add-Err "Manifest entry '$gid' missing icon" }
      if ($mg.url -ne "games/$gid.json") {
        Add-Err "Manifest entry '$gid' url mismatch: '$($mg.url)' (expected 'games/$gid.json')"
      }
      if (-not $mg.updated_at -or ($mg.updated_at -notmatch $isoRegex)) {
        Add-Err "Manifest entry '$gid' updated_at invalid: '$($mg.updated_at)'"
      } elseif ($manifest.updated_at -match $isoRegex -and [datetime]::Parse($mg.updated_at) -gt [datetime]::Parse($manifest.updated_at)) {
        Add-Err "Manifest entry '$gid' updated_at ($($mg.updated_at)) is newer than root manifest updated_at ($($manifest.updated_at))"
      }
      $manifestById[$gid] = $mg
    }
  }
}

$diskJsonFiles = Get-ChildItem (Join-Path $gamesDir '*.json') -ErrorAction SilentlyContinue
if ($null -ne $manifest) {
  foreach ($f in $diskJsonFiles) {
    $base = $f.BaseName
    if (-not $manifestById.ContainsKey($base)) {
      Add-Err "Orphan game file 'games/$($f.Name)' is not registered in games_manifest.json"
    }
  }
}

$targets = @()
if (-not [string]::IsNullOrWhiteSpace($GameId)) {
  if ($manifest -and -not $manifestById.ContainsKey($GameId)) {
    Add-Err "Target GameId '$GameId' is not registered in games_manifest.json"
  }
  $targets = @($GameId)
} elseif ($null -ne $manifest) {
  $targets = @($manifest.games | ForEach-Object { [string]$_.id })
}

foreach ($gid in $targets) {
  $gPath = Join-Path $gamesDir "$gid.json"
  if (-not (Test-Path $gPath)) {
    Add-Err "Missing game JSON file: games/$gid.json"
    continue
  }

  try {
    $g = Get-Content $gPath -Raw -Encoding UTF8 | ConvertFrom-Json
  } catch {
    Add-Err "Invalid JSON syntax in games/$gid.json: $($_.Exception.Message)"
    continue
  }

  $rootProps = @($g.PSObject.Properties.Name)
  foreach ($rk in $reqRootKeys) {
    if ($rootProps -notcontains $rk) {
      Add-Err "games/$gid.json missing required root field '$rk'"
    }
  }
  foreach ($fk in $forbiddenRootKeys) {
    if ($rootProps -contains $fk) {
      Add-Err "games/$gid.json contains forbidden/legacy root field '$fk'"
    }
  }

  if ($g.id -ne $gid) {
    Add-Err "games/$gid.json root 'id' ('$($g.id)') does not match filename '$gid'"
  }
  if ($manifestById.ContainsKey($gid)) {
    $mg = $manifestById[$gid]
    if ($g.title -ne $mg.title) { Add-Err "games/$gid.json title ('$($g.title)') != manifest title ('$($mg.title)')" }
    if ($g.icon -ne $mg.icon) { Add-Err "games/$gid.json icon != manifest icon for '$gid'" }
    if ($g.updated_at -ne $mg.updated_at) { Add-Err "games/$gid.json updated_at ('$($g.updated_at)') != manifest updated_at ('$($mg.updated_at)')" }
  }
  if (-not $g.updated_at -or ($g.updated_at -notmatch $isoRegex)) {
    Add-Err "games/$gid.json invalid updated_at: '$($g.updated_at)'"
  }

  if (-not $g.sources -or $g.sources.Count -eq 0) {
    Add-Err "games/$gid.json 'sources' must be a non-empty array"
  } else {
    foreach ($s in $g.sources) {
      if ([string]::IsNullOrWhiteSpace($s.name) -or [string]::IsNullOrWhiteSpace($s.license) -or ($s.url -notmatch '^https?://')) {
        Add-Err "games/$gid.json has invalid source item (requires name, https/http url, license)"
      }
    }
  }

  if (-not $g.process_keywords -or $g.process_keywords.Count -eq 0) {
    Add-Err "games/$gid.json 'process_keywords' must be a non-empty array"
  } else {
    foreach ($kw in $g.process_keywords) {
      $sKw = [string]$kw
      if ($sKw.Length -lt 4) { Add-Warn "games/$gid.json process_keyword '$sKw' shorter than 4 chars (only exact .exe matches)" }
      if ($sKw -cmatch '[A-Z]') { Add-Err "games/$gid.json process_keyword '$sKw' must be lowercase" }
      if ($sKw -match '\.exe$') { Add-Err "games/$gid.json process_keyword '$sKw' must not end with .exe" }
      if ($sKw -match 'quickwik') { Add-Err "games/$gid.json process_keyword '$sKw' must not contain quickwik" }
    }
  }

  $catIds = New-Object 'System.Collections.Generic.HashSet[string]'
  if (-not $g.categories -or $g.categories.Count -lt 2) {
    Add-Err "games/$gid.json 'categories' must have 'all' plus at least 1 category"
  } else {
    if ($g.categories[0].id -ne 'all' -or $g.categories[0].label -ne 'Todos') {
      Add-Err "games/$gid.json categories[0] must be { id: 'all', label: 'Todos' }"
    }
    foreach ($c in $g.categories) {
      $cid = [string]$c.id
      if ([string]::IsNullOrWhiteSpace($cid) -or [string]::IsNullOrWhiteSpace($c.label)) {
        Add-Err "games/$gid.json has category with empty id or label"
      }
      if ($cid -eq '__favorites__') {
        Add-Err "games/$gid.json must not define reserved category '__favorites__'"
      }
      if (-not $catIds.Add($cid)) {
        Add-Err "games/$gid.json duplicate category id '$cid'"
      }
    }
  }

  $seenEntryIds = New-Object 'System.Collections.Generic.HashSet[int]'
  $imgCount = 0
  if (-not $g.entries -or $g.entries.Count -eq 0) {
    Add-Err "games/$gid.json 'entries' is empty"
  } else {
    foreach ($e in $g.entries) {
      $eid = 0
      try { $eid = [int]$e.id } catch { $eid = -1 }
      if ($eid -le 0 -or -not $seenEntryIds.Add($eid)) {
        Add-Err "games/$gid.json invalid or duplicate entry id '$($e.id)'"
        continue
      }
      if ([string]::IsNullOrWhiteSpace($e.title) -or [string]::IsNullOrWhiteSpace($e.subtitle) -or [string]::IsNullOrWhiteSpace($e.tags)) {
        Add-Err "games/$gid.json entry id=$eid missing title, subtitle, or tags"
      }
      if ($e.category -eq 'all' -or -not $catIds.Contains([string]$e.category)) {
        Add-Err "games/$gid.json entry id=$eid invalid category '$($e.category)'"
      }
      if ($e.spoiler -isnot [bool]) {
        Add-Err "games/$gid.json entry id=$eid spoiler must be boolean"
      }
      if (-not $e.additional_data -or $e.additional_data.Count -eq 0) {
        Add-Err "games/$gid.json entry id=$eid additional_data is empty"
      } else {
        foreach ($card in $e.additional_data) {
          if ([string]::IsNullOrWhiteSpace($card.title) -or [string]::IsNullOrWhiteSpace($card.content)) {
            Add-Err "games/$gid.json entry id=$eid card missing title or content"
          }
          if ($validTypes -notcontains [string]$card.type) {
            Add-Err "games/$gid.json entry id=$eid invalid card type '$($card.type)'"
          }
          if ($validColors -notcontains [string]$card.color) {
            Add-Err "games/$gid.json entry id=$eid invalid card color '$($card.color)'"
          }
          if ($card.type -eq 'image') {
            $fn = [string]$card.content
            if ($fn -match '[/\\]|\.\.' -or $fn -notmatch '^[a-z0-9_.-]+\.webp$') {
              Add-Err "games/$gid.json entry id=$eid invalid/unsafe image filename '$fn'"
            } else {
              $imgPath = Join-Path (Join-Path (Join-Path $gamesDir 'images') $gid) $fn
              if (-not (Test-Path $imgPath)) {
                Add-Err "games/$gid.json entry id=$eid missing image file 'games/images/$gid/$fn'"
              } else {
                $bytes = [System.IO.File]::ReadAllBytes($imgPath)
                if ($bytes.Length -lt 12) {
                  Add-Err "games/$gid.json entry id=$eid image '$fn' too small"
                } else {
                  $h1 = [System.Text.Encoding]::ASCII.GetString($bytes, 0, 4)
                  $h2 = [System.Text.Encoding]::ASCII.GetString($bytes, 8, 4)
                  if ($h1 -ne 'RIFF' -or $h2 -ne 'WEBP') {
                    Add-Err "games/$gid.json entry id=$eid image '$fn' has invalid WEBP header ($h1/$h2)"
                  } else {
                    $imgCount++
                  }
                }
              }
            }
          } elseif ($card.type -in @('youtube', 'video', 'yt')) {
            if ($card.content -notmatch '^https://(www\.youtube\.com/watch\?v=|youtu\.be/)[A-Za-z0-9_-]{11}') {
              Add-Err "games/$gid.json entry id=$eid invalid YouTube URL '$($card.content)'"
            }
          }
          if ($card.type -eq 'text') {
            $gh1 = [regex]::Matches([string]$card.content, $forbiddenGlossary, 'IgnoreCase')
            $gh2 = [regex]::Matches([string]$card.title, $forbiddenGlossary, 'IgnoreCase')
            if ($gh1.Count -gt 0 -or $gh2.Count -gt 0) {
              $terms = (($gh1 + $gh2) | ForEach-Object { $_.Value }) -join ', '
              Add-Err "games/$gid.json entry id=$eid contains forbidden glossary term(s): $terms"
            }
          }
        }
      }

      $tHits = [regex]::Matches(([string]$e.title + ' ' + [string]$e.subtitle), $forbiddenGlossary, 'IgnoreCase')
      if ($tHits.Count -gt 0) {
        $terms = ($tHits | ForEach-Object { $_.Value }) -join ', '
        Add-Err "games/$gid.json entry id=$eid title/subtitle contains forbidden glossary term(s): $terms"
      }
    }
  }

  # ID Stability check against git HEAD when file already existed cleanly
  $gitCmd = Get-Command git -ErrorAction SilentlyContinue
  if ($gitCmd) {
    $prevRaw = & git -C $root show "HEAD:games/$gid.json" 2>$null
    if ($LASTEXITCODE -eq 0 -and $prevRaw) {
      try {
        $prevObj = ($prevRaw -join "`n") | ConvertFrom-Json
        foreach ($pe in $prevObj.entries) {
          if (-not $seenEntryIds.Contains([int]$pe.id)) {
            Add-Err "games/$gid.json broke ID stability: previous id=$($pe.id) ('$($pe.title)') was removed or renumbered!"
          }
        }
      } catch {
        Add-Warn "Could not parse HEAD:games/$gid.json for ID stability comparison"
      }
    }
  }

  Write-Output ("CHECKED " + $gid + ": entries=" + $seenEntryIds.Count + ", images=" + $imgCount + ", updated_at=" + $g.updated_at)
}

if ($warnings.Count -gt 0) {
  Write-Output '--- WARNINGS ---'
  $warnings | ForEach-Object { Write-Output "WARN: $_" }
}

if ($errors.Count -gt 0) {
  Write-Output '--- ERRORS ---'
  $errors | ForEach-Object { Write-Output "ERR: $_" }
  Write-Output "VEREDICTO: REPROVADO ($($errors.Count) erro(s))"
  exit 1
} else {
  Write-Output "VEREDICTO: APROVADO ($($targets.Count) jogo(s) validados sem erros)"
  exit 0
}
