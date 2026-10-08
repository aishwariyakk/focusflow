# ===================================================================
#  FocusFlow - Notification Engine  (Windows PowerShell 5.1+)
#  - Uses Windows Explorer AppID to bypass Focus Assist
#  - Falls back through 4 methods to guarantee visibility
#  - Logs every action to notify.log
# ===================================================================

# --- Locate app folder ---
if ($PSScriptRoot -and $PSScriptRoot -ne '') {
    $AppDir = $PSScriptRoot
} else {
    $AppDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
if (-not $AppDir) { $AppDir = "C:\Users\AishwariyaKK\.bob\playground\focusflow" }

$StateFile = Join-Path $AppDir "state.json"
$HtmlFile  = Join-Path $AppDir "index.html"
$LogFile   = Join-Path $AppDir "notify.log"

# =====================================================
#  FUNCTIONS  (all defined first -- required by PS 5.1)
# =====================================================

function Write-Log {
    param([string]$Msg)
    $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    try {
        [System.IO.File]::AppendAllText($LogFile, "[$ts] $Msg`r`n", [System.Text.Encoding]::UTF8)
    } catch {}
}

function Get-TaskPriority {
    param($T)
    if ($T.priority -eq 'high') { return 0 }
    if ($T.priority -eq 'low')  { return 2 }
    return 1
}

function Open-FocusFlow {
    try { Start-Process $HtmlFile -ErrorAction SilentlyContinue } catch {}
}

function Show-Toast {
    param([string]$Title, [string]$Body, [string]$Scenario = "reminder")

    $shown = $false

    # --- Method 1: WinRT toast via Windows Explorer AppID ---
    # Explorer's AppID bypasses Focus Assist / Do Not Disturb
    try {
        $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
        $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]

        # Use Windows Explorer AppID -- it has highest toast priority on Win 10/11
        $appId = 'Microsoft.Windows.Explorer'

        $safeTitle = [System.Security.SecurityElement]::Escape($Title)
        $safeBody  = [System.Security.SecurityElement]::Escape($Body)

        # scenario="alarm" keeps toast on screen until dismissed (doesn't auto-hide)
        $xml = @"
<toast scenario="alarm" duration="long">
  <visual>
    <binding template="ToastGeneric">
      <text hint-maxLines="1">$safeTitle</text>
      <text>$safeBody</text>
    </binding>
  </visual>
  <actions>
    <action content="Open FocusFlow" arguments="open"  activationType="protocol" />
    <action content="Dismiss"        arguments="close" activationType="system"   hint-action-id="dismiss"/>
  </actions>
  <audio src="ms-winsoundevent:Notification.Reminder" loop="false"/>
</toast>
"@
        $doc      = New-Object Windows.Data.Xml.Dom.XmlDocument
        $doc.LoadXml($xml)
        $toast    = [Windows.UI.Notifications.ToastNotification]::new($doc)
        $toast.Tag      = "focusflow"
        $toast.Group    = "reminders"
        # ExpirationTime: keep in Action Center for 1 hour
        $toast.ExpirationTime = [DateTimeOffset]::Now.AddHours(1)
        $notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
        $notifier.Show($toast)
        $shown = $true
        Write-Log "WinRT toast shown OK (Explorer AppID, scenario=alarm)"
    } catch {
        Write-Log "WinRT toast failed: $($_.Exception.Message)"
    }

    # --- Method 2: PowerShell AppID fallback ---
    if (-not $shown) {
        try {
            $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
            $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
            $appId2 = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
            $safeTitle2 = [System.Security.SecurityElement]::Escape($Title)
            $safeBody2  = [System.Security.SecurityElement]::Escape($Body)
            $xml2 = @"
<toast duration="long">
  <visual><binding template="ToastGeneric">
    <text>$safeTitle2</text><text>$safeBody2</text>
  </binding></visual>
  <audio src="ms-winsoundevent:Notification.Reminder"/>
</toast>
"@
            $doc2  = New-Object Windows.Data.Xml.Dom.XmlDocument
            $doc2.LoadXml($xml2)
            $t2    = [Windows.UI.Notifications.ToastNotification]::new($doc2)
            $n2    = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId2)
            $n2.Show($t2)
            $shown = $true
            Write-Log "WinRT toast shown OK (PS AppID)"
        } catch {
            Write-Log "WinRT PS AppID failed: $($_.Exception.Message)"
        }
    }

    # --- Method 3: WScript.Shell Popup --- always appears on top, auto-closes 20s
    if (-not $shown) {
        try {
            $wsh = New-Object -ComObject WScript.Shell
            $wsh.Popup("$Body", 20, $Title, 48) | Out-Null   # 48 = OK + Info icon
            $shown = $true
            Write-Log "WScript popup shown"
        } catch {
            Write-Log "WScript popup failed: $($_.Exception.Message)"
        }
    }

    # --- Method 4: msg.exe --- Direct Windows message, appears over everything
    if (-not $shown) {
        try {
            $u = $env:USERNAME
            $m = "$Title - $Body"
            if ($m.Length -gt 500) { $m = $m.Substring(0, 500) }
            cmd /c "msg $u /time:30 `"$m`"" 2>$null
            Write-Log "msg.exe shown"
        } catch {
            Write-Log "msg.exe failed: $($_.Exception.Message)"
        }
    }
}

# =====================================================
#  MAIN
# =====================================================

Write-Log "--- notify.ps1 started ---"

# --- Guard: no state file ---
if (-not (Test-Path $StateFile)) {
    Write-Log "state.json missing -- showing setup prompt"
    Open-FocusFlow
    Show-Toast -Title "FocusFlow - Set Up Your Day" `
               -Body "No tasks found yet. FocusFlow is opening so you can plan your day."
    exit 0
}

# --- Load state ---
try {
    $raw   = [System.IO.File]::ReadAllText($StateFile, [System.Text.Encoding]::UTF8)
    $state = $raw | ConvertFrom-Json
} catch {
    Write-Log "JSON parse error: $($_.Exception.Message)"
    exit 1
}

$today = (Get-Date).ToString("yyyy-MM-dd")
Write-Log "State date=$($state.date)  Today=$today"

# --- Stale state (yesterday or older) ---
if ($state.date -ne $today) {
    Write-Log "Stale state detected -- prompting new day setup"
    Open-FocusFlow
    Show-Toast -Title "FocusFlow - Good morning!" `
               -Body "A new day is here! Open FocusFlow to plan your tasks for today."
    exit 0
}

# --- Count tasks (guard against null tasks array) ---
if ($state.tasks) {
    $allTasks = @($state.tasks | Where-Object { $_ -ne $null })
} else {
    $allTasks = @()
}
$pending   = @($allTasks | Where-Object { -not $_.done })
$doneList  = @($allTasks | Where-Object {  $_.done })
$total     = $allTasks.Count
$pndCount  = $pending.Count
$doneCount = $doneList.Count
$pct       = if ($total -gt 0) { [int](($doneCount / $total) * 100) } else { 0 }

Write-Log "Count: total=$total done=$doneCount pending=$pndCount ($pct%)"

# --- All done ---
if ($total -gt 0 -and $pndCount -eq 0) {
    Write-Log "All tasks complete!"
    Open-FocusFlow
    Show-Toast -Title "FocusFlow - All Done!" `
               -Body "You completed every task today ($total/$total). Amazing work! Your streak continues."
    exit 0
}

# --- No tasks set up yet ---
if ($total -eq 0) {
    Write-Log "No tasks in state"
    Open-FocusFlow
    Show-Toast -Title "FocusFlow - Add Your Tasks" `
               -Body "No tasks found for today. Open FocusFlow to set up your day."
    exit 0
}

# --- Build task summary lines ---
$sorted   = $pending | Sort-Object { Get-TaskPriority $_ }
$topTasks = @($sorted | Select-Object -First 4)

$lines = @()
foreach ($t in $topTasks) {
    $mark = if ($t.priority -eq 'high') { '[!]' } elseif ($t.priority -eq 'low') { '[ ]' } else { '[~]' }
    $lines += "$mark $($t.label)"
}
$body = ($lines -join "`n")
if ($pndCount -gt 4) { $body += "`n   ...and $($pndCount - 4) more" }

$num   = if ($state.reminderCount) { [int]$state.reminderCount + 1 } else { 1 }
$title = "FocusFlow - Check-in #$num  ($pct% complete)"
$full  = "$doneCount of $total tasks done - $pndCount remaining`n`n$body"

Write-Log "Showing toast: $title"
Show-Toast -Title $title -Body $full
Open-FocusFlow

Write-Log "Done."
exit 0
