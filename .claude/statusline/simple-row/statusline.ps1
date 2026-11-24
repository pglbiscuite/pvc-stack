# Claude Code status line: one simple row.
#
#   Opus 5.5 . max | context #------- 17% | week -------- 0% | 5d 14h | ultracode ON
#
# From the left: the model, the effort level, the context window, then each usage limit that
# the account has (5 hours, 7 days) with the time left to its reset, then the ultracode switch
# of the settings files. The real row draws the bars as solid cells and puts a middle dot after
# the model.
#
# Claude Code sends the session as JSON on stdin: https://code.claude.com/docs/en/statusline
# This file is plain ASCII. The bar cell and the dot are built from character codes, and the
# output goes out as UTF-8, so Windows PowerShell 5.1 shows them right.
# The row must never fail: any error still ends in a row of text and exit code 0.
#
#   powershell -NoProfile -ExecutionPolicy Bypass -File statusline.ps1 -SelfTest     run the checks and print sample rows

param([switch]$SelfTest)

$ErrorActionPreference = 'Stop'
try {
    $utf8 = New-Object System.Text.UTF8Encoding $false
    [Console]::OutputEncoding = $utf8
    [Console]::InputEncoding = $utf8
} catch { }

$ESC = [string][char]27
$CELL = [string][char]0x2588      # one bar cell, a full block
$DOT = [string][char]0x00B7       # the middle dot between the model and the effort
$BAR_WIDTHS = @(8, 6, 4, 0)       # tried in this order until the row fits the terminal

# The basic ANSI colors, so the row follows the terminal's own palette.
$COLOR = @{
    cyan   = $ESC + '[36m'
    green  = $ESC + '[32m'
    yellow = $ESC + '[33m'
    red    = $ESC + '[31m'
    blue   = $ESC + '[34m'
    grey   = $ESC + '[90m'
    pink   = $ESC + '[95m'        # the terminal's bright magenta
    track  = $ESC + '[30m'        # the empty part of a bar: the terminal's black, a dark slot
    none   = ''
}
$RESET = $ESC + '[0m'

# The usage limits in the order they are drawn: the key in rate_limits, then the label.
$WINDOWS = @(@('five_hour', '5h'), @('seven_day', 'week'))


# ---------- reading the input ----------

function Get-Field($obj, [string[]]$path) {
    # The value at a path of keys, or $null when a step is missing or is no object.
    $cur = $obj
    foreach ($key in $path) {
        if ($null -eq $cur) { return $null }
        if ($cur -is [System.Collections.IDictionary]) {
            if (-not $cur.Contains($key)) { return $null }
            $cur = $cur[$key]
        } elseif ($cur -is [string] -or $cur -is [ValueType] -or $cur -is [array]) {
            return $null
        } else {
            $prop = $cur.PSObject.Properties[$key]
            if ($null -eq $prop) { return $null }
            $cur = $prop.Value
        }
    }
    return $cur
}

function ConvertTo-Number($value, [switch]$AllowText) {
    # A finite number, or $null. A bool is no number here. Text counts only with -AllowText.
    if ($null -eq $value -or $value -is [bool] -or $value -is [char]) { return $null }
    if ($value -is [string]) {
        if (-not $AllowText) { return $null }
        $parsed = 0.0
        $style = [System.Globalization.NumberStyles]::Float
        $culture = [System.Globalization.CultureInfo]::InvariantCulture
        if (-not [double]::TryParse($value.Trim(), $style, $culture, [ref]$parsed)) { return $null }
        $value = $parsed
    }
    if (-not ($value -is [ValueType])) { return $null }
    try { $number = [double]$value } catch { return $null }
    if ([double]::IsNaN($number) -or [double]::IsInfinity($number)) { return $null }
    return $number
}

function Get-Text($value, [int]$limit) {
    # A short one-line string, or ''. A control character would break the row.
    if (-not ($value -is [string])) { return '' }
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $value.ToCharArray()) {
        $code = [int]$ch
        if ($code -lt 32 -or ($code -ge 127 -and $code -lt 160)) { continue }
        [void]$sb.Append($ch)
        if ($sb.Length -ge $limit) { break }
    }
    return $sb.ToString().Trim()
}

function Read-Setting([string]$path, [string]$key) {
    # The value of one top-level key of a settings file, or $null: no file, no JSON, no such key.
    try {
        if (-not $path -or -not [System.IO.File]::Exists($path)) { return $null }
        if ((New-Object System.IO.FileInfo $path).Length -gt 1000000) { return $null }
        $text = [System.IO.File]::ReadAllText($path).TrimStart([char]0xFEFF)
        return (Get-Field ($text | ConvertFrom-Json) @($key))
    } catch { return $null }
}

function Get-Ultra($data, [string]$configDir, [string]$userHome) {
    # $true or $false from the key "ultracode" of the settings files, or $null when no file has
    # it. The nearest file wins: the local file of the project, the shared file of the project,
    # then the user file. Claude Code sends a status line no such field, so a change made inside
    # a session (/effort ultracode) does not show here.
    try {
        $paths = New-Object System.Collections.ArrayList
        $project = Get-Text (Get-Field $data @('workspace', 'project_dir')) 400
        if ($project) {
            [void]$paths.Add([System.IO.Path]::Combine($project, '.claude', 'settings.local.json'))
            [void]$paths.Add([System.IO.Path]::Combine($project, '.claude', 'settings.json'))
        }
        $folder = ([string]$configDir).Trim().Trim('"')
        if (-not $folder -and $userHome) { $folder = [System.IO.Path]::Combine($userHome, '.claude') }
        if ($folder) { [void]$paths.Add([System.IO.Path]::Combine($folder, 'settings.json')) }
        foreach ($path in $paths) {
            $value = Read-Setting $path 'ultracode'
            if ($value -is [bool]) { return $value }
        }
    } catch { }
    return $null
}


# ---------- the numbers ----------

function Get-Shown([double]$pct) {
    # The whole percent on screen. 100 only when the limit is reached.
    if ($pct -ge 100) { return 100 }
    $whole = [int][math]::Floor($pct + 0.5)
    if ($whole -lt 0) { return 0 }
    if ($whole -gt 99) { return 99 }
    return $whole
}

function Get-Tone([int]$shown) {
    # The color of a meter: cyan while low, yellow from 60, red from 85.
    if ($shown -ge 85) { return 'red' }
    if ($shown -ge 60) { return 'yellow' }
    return 'cyan'
}

function Get-Left($resets, [double]$now) {
    # The time left to a reset: 3d 0h, 2h 58m, 58m. '' when unknown or past.
    $ts = ConvertTo-Number $resets -AllowText
    if ($null -eq $ts) { return '' }
    if ($ts -gt 100000000000) { $ts = $ts / 1000 }      # milliseconds
    if ($ts -le $now) { return '' }
    $mins = [long][math]::Floor(($ts - $now) / 60)
    $hours = [long][math]::Floor($mins / 60)
    $days = [long][math]::Floor($mins / 1440)
    if ($days -gt 0) { return ('{0}d {1}h' -f $days, ($hours % 24)) }
    if ($hours -gt 0) { return ('{0}h {1}m' -f $hours, ($mins % 60)) }
    return ('{0}m' -f $mins)
}


# ---------- drawing ----------
# A row is a list of segments. A segment is a pair: the color name, then the text.

function Add-Seg($segs, [string]$color, [string]$text) {
    [void]$segs.Add(@($color, $text))
}

function Add-Meter($segs, [string]$label, $pct, [int]$barWidth) {
    # The label, the bar and the percent. With no number: the label and two dashes.
    Add-Seg $segs 'grey' ($label + ' ')
    if ($null -eq $pct) {
        Add-Seg $segs 'grey' '--'
        return
    }
    $shown = Get-Shown $pct
    $tone = Get-Tone $shown
    if ($barWidth -gt 0) {
        $filled = [int][math]::Floor($shown * $barWidth / 100.0 + 0.5)
        if ($shown -lt 100 -and $filled -gt ($barWidth - 1)) { $filled = $barWidth - 1 }   # a full bar means the limit is reached
        if ($filled -lt 0) { $filled = 0 }
        if ($filled -gt 0) { Add-Seg $segs $tone ($CELL * $filled) }
        if ($barWidth - $filled -gt 0) { Add-Seg $segs 'track' ($CELL * ($barWidth - $filled)) }
        Add-Seg $segs 'none' ' '
    }
    Add-Seg $segs $tone ('{0}%' -f $shown)
}

function Get-Row($data, [double]$now, [int]$barWidth, [bool]$times, $ultra) {
    # $ultra: $true or $false draws the ultracode part at the end, $null leaves it out.
    $segs = New-Object System.Collections.ArrayList

    $model = Get-Text (Get-Field $data @('model', 'display_name')) 40
    if (-not $model) { $model = 'Claude' }
    Add-Seg $segs 'cyan' $model

    $effort = Get-Text (Get-Field $data @('effort', 'level')) 10
    if ($effort) {
        Add-Seg $segs 'grey' (' ' + $DOT + ' ')
        if ($effort -ceq 'max') {
            Add-Seg $segs 'red' 'm'
            Add-Seg $segs 'yellow' 'a'
            Add-Seg $segs 'blue' 'x'
        } else {
            Add-Seg $segs 'none' $effort
        }
    }
    $fast = Get-Field $data @('fast_mode')
    if ($fast -is [bool] -and $fast) {
        Add-Seg $segs 'grey' (' ' + $DOT + ' ')
        Add-Seg $segs 'yellow' 'fast'
    }

    $used = ConvertTo-Number (Get-Field $data @('context_window', 'used_percentage'))
    if ($null -eq $used) {
        $free = ConvertTo-Number (Get-Field $data @('context_window', 'remaining_percentage'))
        if ($null -ne $free) { $used = 100.0 - $free }
    }
    Add-Seg $segs 'grey' ' | '
    Add-Meter $segs 'context' $used $barWidth

    foreach ($window in $WINDOWS) {
        $entry = Get-Field $data @('rate_limits', $window[0])
        $pct = ConvertTo-Number (Get-Field $entry @('used_percentage'))
        if ($null -eq $pct) { continue }       # the account has no such limit, or no reply came yet
        Add-Seg $segs 'grey' ' | '
        Add-Meter $segs $window[1] $pct $barWidth
        if ($times) {
            $left = Get-Left (Get-Field $entry @('resets_at')) $now
            if ($left) {
                Add-Seg $segs 'grey' ' | '
                Add-Seg $segs 'green' $left
            }
        }
    }
    if ($ultra -is [bool]) {
        Add-Seg $segs 'grey' ' | ultracode '
        if ($ultra) { Add-Seg $segs 'pink' 'ON' } else { Add-Seg $segs 'grey' 'OFF' }
    }
    return ,$segs
}

function Get-Width($segs) {
    $total = 0
    foreach ($seg in $segs) { $total += $seg[1].Length }
    return $total
}

function Get-Fitted($data, [double]$now, [int]$limit, $ultra) {
    # The first layout that fits: the bars get shorter, then they go, then the times go, then the
    # ultracode part goes. When none fits, the smallest one is cut between its parts, so a
    # number never shows in part. A layout is: the bar width, the times, the ultracode part.
    $layouts = New-Object System.Collections.ArrayList
    foreach ($barWidth in $BAR_WIDTHS) { [void]$layouts.Add(@($barWidth, $true, $true)) }
    [void]$layouts.Add(@(0, $false, $true))
    if ($ultra -is [bool]) { [void]$layouts.Add(@(0, $false, $false)) }
    $segs = $null
    foreach ($layout in $layouts) {
        $part = $null
        if ($layout[2]) { $part = $ultra }
        $segs = Get-Row $data $now $layout[0] $layout[1] $part
        if ((Get-Width $segs) -le $limit) { return ,$segs }
    }
    $cut = New-Object System.Collections.ArrayList
    $room = [math]::Max(0, $limit)
    foreach ($seg in $segs) {
        if ($room -le 0) { break }
        $text = $seg[1]
        if ($text.Length -gt $room) {
            if ($cut.Count -gt 0) { break }
            $text = $text.Substring(0, $room)
        }
        Add-Seg $cut $seg[0] $text
        $room -= $text.Length
    }
    while ($cut.Count -gt 1 -and ($cut[$cut.Count - 1][0] -eq 'grey' -or -not $cut[$cut.Count - 1][1].Trim())) {
        $cut.RemoveAt($cut.Count - 1)        # no separator and no label without its number at the end
    }
    if ($cut.Count -gt 0) {
        $last = $cut[$cut.Count - 1]
        $trimmed = $last[1].TrimEnd()
        if ($trimmed) { $cut[$cut.Count - 1] = @($last[0], $trimmed) }    # no space at the end of a cut row
    }
    return ,$cut
}

function Get-Painted($segs) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($seg in $segs) {
        $code = $COLOR[$seg[0]]
        if ($code) {
            [void]$sb.Append($code).Append($seg[1]).Append($RESET)
        } else {
            [void]$sb.Append($seg[1])
        }
    }
    return $sb.ToString()
}

function Get-Plain($segs) {
    # The row with no color codes: a filled cell reads #, an empty one reads -.
    $sb = New-Object System.Text.StringBuilder
    foreach ($seg in $segs) {
        if ($seg[0] -eq 'track') {
            [void]$sb.Append($seg[1].Replace($CELL, '-'))
        } else {
            [void]$sb.Append($seg[1].Replace($CELL, '#'))
        }
    }
    return $sb.ToString()
}


# ---------- the run ----------

function Get-Now {
    $start = New-Object datetime 1970, 1, 1, 0, 0, 0, ([DateTimeKind]::Utc)
    return ([datetime]::UtcNow - $start).TotalSeconds
}

function Get-Limit([string]$columns) {
    # The room for the row: the terminal width that Claude Code gives, less a small margin.
    $cols = 0
    if ([int]::TryParse($columns, [ref]$cols) -and $cols -gt 0) { return [math]::Max(1, $cols - 4) }
    return 200
}

function Read-Stdin {
    try {
        if ([Console]::IsInputRedirected) { return [Console]::In.ReadToEnd() }
    } catch { }
    return ''
}

function ConvertFrom-Stdin([string]$raw) {
    if (-not $raw) { return $null }
    $raw = $raw.TrimStart([char]0xFEFF)
    if (-not $raw.Trim()) { return $null }
    try { return ($raw | ConvertFrom-Json) } catch { return $null }
}


# ---------- the checks ----------

function Invoke-SelfTest {
    $fails = New-Object System.Collections.ArrayList
    $count = 0
    $now = 1800000000.0
    $week = $now + 5 * 86400 + 14 * 3600 + 30
    $five = $now + 2 * 3600 + 58 * 60 + 5

    function Test-Same([string]$name, $got, $want) {
        Set-Variable -Name count -Value ($count + 1) -Scope 1
        if ([string]$got -cne [string]$want) {
            [void]$fails.Add(('{0}' -f $name) + "`n     got:  " + [string]$got + "`n     want: " + [string]$want)
        }
    }
    function Get-Sample([string]$json) { return ($json | ConvertFrom-Json) }
    function Get-PlainRow($data, [int]$limit, $ultra) { return (Get-Plain (Get-Fitted $data $now $limit $ultra)) }

    $full = Get-Sample ('{"model":{"id":"x","display_name":"Opus 5.5"},"effort":{"level":"max"},"fast_mode":false,' +
        '"context_window":{"used_percentage":17},"rate_limits":{"seven_day":{"used_percentage":0,"resets_at":' + [string][long]$week + '}}}')
    $both = Get-Sample ('{"model":{"display_name":"Opus 5.5"},"effort":{"level":"high"},' +
        '"context_window":{"used_percentage":63.4},"rate_limits":{"five_hour":{"used_percentage":45,"resets_at":' + [string][long]$five + '},' +
        '"seven_day":{"used_percentage":91,"resets_at":' + [string][long]$week + '}}}')
    $bare = Get-Sample '{"model":{"display_name":"Sonnet 5.5"},"context_window":{"remaining_percentage":70}}'
    $junk = Get-Sample ('{"model":5,"effort":"max","fast_mode":"yes","context_window":{"used_percentage":"12"},' +
        '"rate_limits":{"five_hour":[1],"seven_day":{"used_percentage":true,"resets_at":"x"}}}')

    # 1. the row of the picture
    Test-Same 'the full row' (Get-PlainRow $full 200) ('Opus 5.5 ' + $DOT + ' max | context #------- 17% | week -------- 0% | 5d 14h')
    $painted = Get-Painted (Get-Fitted $full $now 200)
    Test-Same 'one line' ($painted.Contains("`n") -or $painted.Contains("`r")) $false
    Test-Same 'the model is cyan' $painted.Contains($COLOR['cyan'] + 'Opus 5.5' + $RESET) $true
    Test-Same 'max is m red, a yellow, x blue' $painted.Contains($COLOR['red'] + 'm' + $RESET + $COLOR['yellow'] + 'a' + $RESET + $COLOR['blue'] + 'x' + $RESET) $true
    Test-Same 'the empty part of a bar is the dark slot' $painted.Contains($COLOR['track'] + ($CELL * 7) + $RESET) $true
    Test-Same 'the time left is green' $painted.Contains($COLOR['green'] + '5d 14h' + $RESET) $true

    # 2. both limits, another effort word
    Test-Same 'both limits' (Get-PlainRow $both 200) ('Opus 5.5 ' + $DOT + ' high | context #####--- 63% | 5h ####---- 45% | 2h 58m | week #######- 91% | 5d 14h')
    Test-Same 'the bar before a time is grey' $painted.Contains($COLOR['grey'] + ' | ' + $RESET + $COLOR['green'] + '5d 14h' + $RESET) $true
    $painted = Get-Painted (Get-Fitted $both $now 200)
    Test-Same 'another effort word is plain' $painted.Contains($DOT + ' ' + $RESET + 'high') $true
    Test-Same '63 is yellow' $painted.Contains($COLOR['yellow'] + '63%' + $RESET) $true
    Test-Same '91 is red' $painted.Contains($COLOR['red'] + '91%' + $RESET) $true

    # 3. an account with no limits, and the remaining percent
    Test-Same 'no limits, no effort' (Get-PlainRow $bare 200) 'Sonnet 5.5 | context ##------ 30%'

    # 4. no input and wrong types still give a row
    Test-Same 'no input' (Get-PlainRow $null 200) 'Claude | context --'
    Test-Same 'wrong types' (Get-PlainRow $junk 200) 'Claude | context --'
    Test-Same 'a list as input' (Get-PlainRow (Get-Sample '[1,2]') 200) 'Claude | context --'
    Test-Same 'text that is no JSON' ($null -eq (ConvertFrom-Stdin 'not json {')) $true
    Test-Same 'empty text' ($null -eq (ConvertFrom-Stdin '   ')) $true
    Test-Same 'a byte-order mark' (Get-Field (ConvertFrom-Stdin (([string][char]0xFEFF) + '{"a":{"b":7}}')) @('a', 'b')) 7

    # 5. fast mode
    $fastRow = Get-Sample '{"model":{"display_name":"Opus 5.5"},"effort":{"level":"max"},"fast_mode":true,"context_window":{"used_percentage":1}}'
    Test-Same 'fast mode shows' (Get-PlainRow $fastRow 200) ('Opus 5.5 ' + $DOT + ' max ' + $DOT + ' fast | context -------- 1%')

    # 6. narrow terminals: the row fits and is never empty
    foreach ($cols in @(200, 80, 70, 60, 50, 40, 30, 20, 12, 5, 1)) {
        $limit = Get-Limit ([string]$cols)
        $row = Get-PlainRow $both $limit
        Test-Same ('fits {0} columns' -f $cols) ($row.Length -gt 0 -and $row.Length -le $limit) $true
    }
    # the widths of this row: 94 with bars of 8 cells, 88 with 6, 82 with 4, 67 with no bars, 49 with no times
    $wide = 'Opus 5.5 ' + $DOT + ' high | context #####--- 63% | 5h ####---- 45% | 2h 58m | week #######- 91% | 5d 14h'
    $six = 'Opus 5.5 ' + $DOT + ' high | context ####-- 63% | 5h ###--- 45% | 2h 58m | week #####- 91% | 5d 14h'
    $four = 'Opus 5.5 ' + $DOT + ' high | context ###- 63% | 5h ##-- 45% | 2h 58m | week ###- 91% | 5d 14h'
    $noBars = 'Opus 5.5 ' + $DOT + ' high | context 63% | 5h 45% | 2h 58m | week 91% | 5d 14h'
    $noTimes = 'Opus 5.5 ' + $DOT + ' high | context 63% | 5h 45% | week 91%'
    Test-Same 'the width of the full row' $wide.Length 94
    Test-Same 'the full bars fit exactly' (Get-PlainRow $both 94) $wide
    Test-Same 'one column less: shorter bars' (Get-PlainRow $both 93) $six
    Test-Same 'bars of 6 cells fit exactly' (Get-PlainRow $both 88) $six
    Test-Same 'then bars of 4 cells' (Get-PlainRow $both 87) $four
    Test-Same 'then no bars' (Get-PlainRow $both 81) $noBars
    Test-Same 'no bars fit exactly' (Get-PlainRow $both 67) $noBars
    Test-Same 'then no times' (Get-PlainRow $both 66) $noTimes
    Test-Same 'no times fit exactly' (Get-PlainRow $both 49) $noTimes
    Test-Same 'then the row is cut after a number' (Get-PlainRow $both 48) ('Opus 5.5 ' + $DOT + ' high | context 63% | 5h 45%')
    Test-Same 'a cut row ends on a number' (Get-PlainRow $both 30) ('Opus 5.5 ' + $DOT + ' high | context 63%')
    Test-Same 'a very narrow row keeps the start of the model' (Get-PlainRow $both 5) 'Opus'
    Test-Same 'no COLUMNS value' (Get-Limit '') 200
    Test-Same 'a COLUMNS value that is no number' (Get-Limit 'wide') 200
    Test-Same 'COLUMNS less the margin' (Get-Limit '120') 116

    # 7. the pieces
    Test-Same 'round up' (Get-Shown 31.5) 32
    Test-Same '99.6 is not full' (Get-Shown 99.6) 99
    Test-Same 'full' (Get-Shown 100.0) 100
    Test-Same 'over' (Get-Shown 150.0) 100
    Test-Same 'below zero' (Get-Shown -5.0) 0
    Test-Same '59 is cyan' (Get-Tone 59) 'cyan'
    Test-Same '60 is yellow' (Get-Tone 60) 'yellow'
    Test-Same '84 is yellow' (Get-Tone 84) 'yellow'
    Test-Same '85 is red' (Get-Tone 85) 'red'
    $meter = New-Object System.Collections.ArrayList
    Add-Meter $meter 'w' 95.0 8
    Test-Same '95 is not a full bar' (Get-Plain $meter) 'w #######- 95%'
    $meter = New-Object System.Collections.ArrayList
    Add-Meter $meter 'w' 100.0 8
    Test-Same '100 is a full bar' (Get-Plain $meter) 'w ######## 100%'
    $meter = New-Object System.Collections.ArrayList
    Add-Meter $meter 'w' 0.4 8
    Test-Same 'under half a percent is an empty bar' (Get-Plain $meter) 'w -------- 0%'
    Test-Same 'days and hours' (Get-Left ($now + 3 * 86400) $now) '3d 0h'
    Test-Same 'hours and minutes' (Get-Left ($now + 3600) $now) '1h 0m'
    Test-Same 'minutes' (Get-Left ($now + 59 * 60) $now) '59m'
    Test-Same 'under a minute' (Get-Left ($now + 59) $now) '0m'
    Test-Same 'a past reset' (Get-Left ($now - 5) $now) ''
    Test-Same 'the reset is now' (Get-Left $now $now) ''
    Test-Same 'milliseconds' (Get-Left (($now + 7200) * 1000) $now) '2h 0m'
    Test-Same 'a number in text' (Get-Left ([string][long]($now + 7200)) $now) '2h 0m'
    Test-Same 'text that is no number' (Get-Left 'soon' $now) ''
    Test-Same 'no reset time' (Get-Left $null $now) ''
    Test-Same 'a bool is no number' ($null -eq (ConvertTo-Number $true)) $true
    Test-Same 'text is no percent' ($null -eq (ConvertTo-Number '12')) $true
    Test-Same 'control characters go' (Get-Text ('Opus' + [string][char]27 + '[31m 5' + "`n") 40) 'Opus[31m 5'
    Test-Same 'a long name is cut' (Get-Text ('x' * 90) 40).Length 40
    Test-Same 'a missing step' ($null -eq (Get-Field $full @('model', 'nope', 'deeper'))) $true
    Test-Same 'a step into text' ($null -eq (Get-Field $full @('model', 'display_name', 'Length'))) $true

    # 8. the ultracode part of the row
    Test-Same 'ultracode on' (Get-PlainRow $full 200 $true) ('Opus 5.5 ' + $DOT + ' max | context #------- 17% | week -------- 0% | 5d 14h | ultracode ON')
    Test-Same 'ultracode off' (Get-PlainRow $full 200 $false) ('Opus 5.5 ' + $DOT + ' max | context #------- 17% | week -------- 0% | 5d 14h | ultracode OFF')
    Test-Same 'no ultracode key: no such part' (Get-PlainRow $full 200 $null).Contains('ultracode') $false
    Test-Same 'a value that is no true or false: no such part' (Get-PlainRow $full 200 'yes').Contains('ultracode') $false
    Test-Same 'ON is pink' (Get-Painted (Get-Fitted $full $now 200 $true)).Contains($COLOR['pink'] + 'ON' + $RESET) $true
    Test-Same 'OFF is grey' (Get-Painted (Get-Fitted $full $now 200 $false)).Contains($COLOR['grey'] + 'OFF' + $RESET) $true
    # the widths with the part: 109 with bars of 8 cells, 82 with no bars, 64 with no times, 49 without the part
    Test-Same 'with the part the full bars fit exactly' (Get-PlainRow $both 109 $true) ($wide + ' | ultracode ON')
    Test-Same 'one column less: shorter bars, the part stays' (Get-PlainRow $both 108 $true) ($six + ' | ultracode ON')
    Test-Same 'no bars and the part fit exactly' (Get-PlainRow $both 82 $true) ($noBars + ' | ultracode ON')
    Test-Same 'the times go before the part' (Get-PlainRow $both 81 $true) ($noTimes + ' | ultracode ON')
    Test-Same 'no times and the part fit exactly' (Get-PlainRow $both 64 $true) ($noTimes + ' | ultracode ON')
    Test-Same 'then the part goes' (Get-PlainRow $both 63 $true) $noTimes
    Test-Same 'and then the row is cut after a number' (Get-PlainRow $both 48 $true) ('Opus 5.5 ' + $DOT + ' high | context 63% | 5h 45%')
    foreach ($cols in @(200, 120, 100, 80, 60, 40, 20, 5, 1)) {
        $limit = Get-Limit ([string]$cols)
        $row = Get-PlainRow $both $limit $false
        Test-Same ('with the part the row fits {0} columns' -f $cols) ($row.Length -gt 0 -and $row.Length -le $limit) $true
    }

    # 9. where the ultracode value comes from: the settings files, the nearest file first
    $tmp = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), ('simple-row-selftest-' + [guid]::NewGuid().ToString('N')))
    try {
        $proj = [System.IO.Path]::Combine($tmp, 'proj')
        $userDir = [System.IO.Path]::Combine($tmp, 'user')
        $homeDir = [System.IO.Path]::Combine($tmp, 'home')
        [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($proj, '.claude'))
        [void][System.IO.Directory]::CreateDirectory($userDir)
        [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::Combine($homeDir, '.claude'))
        $local = [System.IO.Path]::Combine($proj, '.claude', 'settings.local.json')
        $shared = [System.IO.Path]::Combine($proj, '.claude', 'settings.json')
        $user = [System.IO.Path]::Combine($userDir, 'settings.json')
        $inProj = Get-Sample ('{"workspace":{"project_dir":' + (ConvertTo-Json $proj) + '}}')
        Test-Same 'no settings file: not known' ($null -eq (Get-Ultra $inProj $userDir $homeDir)) $true
        [System.IO.File]::WriteAllText($user, '{"theme": "dark", "ultracode": true}')
        Test-Same 'the user file says on' (Get-Ultra $inProj $userDir $homeDir) $true
        [System.IO.File]::WriteAllText($shared, '{"ultracode": false}')
        Test-Same 'the project file wins over the user file' (Get-Ultra $inProj $userDir $homeDir) $false
        [System.IO.File]::WriteAllText($local, '{"ultracode": true}')
        Test-Same 'the local file wins over the project file' (Get-Ultra $inProj $userDir $homeDir) $true
        [System.IO.File]::WriteAllText($local, '{"ultracode": "yes"}')
        Test-Same 'a value that is no true or false is passed over' (Get-Ultra $inProj $userDir $homeDir) $false
        [System.IO.File]::WriteAllText($local, 'not json {')
        Test-Same 'a file that is no JSON is passed over' (Get-Ultra $inProj $userDir $homeDir) $false
        [System.IO.File]::WriteAllText($local, '[true]')
        Test-Same 'a file that is a list is passed over' (Get-Ultra $inProj $userDir $homeDir) $false
        [System.IO.File]::WriteAllText($shared, '{"hooks": {}}')
        Test-Same 'a file with no such key is passed over' (Get-Ultra $inProj $userDir $homeDir) $true
        [System.IO.File]::WriteAllText($shared, (([string][char]0xFEFF) + '{"ultracode": false}'), (New-Object System.Text.UTF8Encoding $false))
        Test-Same 'a byte-order mark in a settings file' (Get-Ultra $inProj $userDir $homeDir) $false
        Test-Same 'no project folder: the user file' (Get-Ultra $null $userDir $homeDir) $true
        Test-Same 'quotes around the config folder' (Get-Ultra $null ('"' + $userDir + '"') $homeDir) $true
        [System.IO.File]::WriteAllText([System.IO.Path]::Combine($homeDir, '.claude', 'settings.json'), '{"ultracode": false}')
        Test-Same 'no config folder: the .claude folder of the user' (Get-Ultra $null '' $homeDir) $false
        Test-Same 'no folder at all: not known' ($null -eq (Get-Ultra $null '' '')) $true
        Test-Same 'a project folder that is no text: the user file' (Get-Ultra (Get-Sample '{"workspace":{"project_dir":5}}') $userDir $homeDir) $true
    } finally {
        try { [System.IO.Directory]::Delete($tmp, $true) } catch { }
    }

    # 10. this file is plain ASCII, so no code page can break it
    $bad = 0
    if ($PSCommandPath) {
        foreach ($byte in [System.IO.File]::ReadAllBytes($PSCommandPath)) { if ($byte -gt 126) { $bad += 1 } }
    }
    Test-Same 'this file is plain ASCII' $bad 0

    [Console]::Out.WriteLine('')
    foreach ($sample in @(@('the row', $full, $null), @('both limits', $both, $null), @('ultracode on', $both, $true),
            @('ultracode off', $full, $false), @('no limits', $bare, $null), @('no data', $null, $null))) {
        [Console]::Out.WriteLine('  ' + $sample[0])
        [Console]::Out.WriteLine('    ' + (Get-Painted (Get-Fitted $sample[1] $now 200 $sample[2])))
    }
    [Console]::Out.WriteLine('')
    if ($fails.Count -gt 0) {
        foreach ($fail in $fails) { [Console]::Out.WriteLine('FAIL ' + $fail) }
        [Console]::Out.WriteLine(('selftest: {0} of {1} checks failed' -f $fails.Count, $count))
        return 1
    }
    [Console]::Out.WriteLine(('selftest: ok, {0} checks' -f $count))
    return 0
}


if ($SelfTest) {
    $code = 1
    try { $code = Invoke-SelfTest } catch { [Console]::Out.WriteLine('selftest: the test itself failed: ' + $_) }
    exit $code
}

$row = 'Claude'
try {
    $data = ConvertFrom-Stdin (Read-Stdin)
    $ultra = $null
    try { $ultra = Get-Ultra $data ([string]$env:CLAUDE_CONFIG_DIR) ([Environment]::GetFolderPath('UserProfile')) } catch { }
    $row = Get-Painted (Get-Fitted $data (Get-Now) (Get-Limit ([string]$env:COLUMNS)) $ultra)
} catch { }
try { [Console]::Out.Write($row) } catch { $row }      # a host that allows no method call still gets the row
exit 0
