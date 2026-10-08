# ===================================================================
#  FocusFlow - Notification Scheduler Setup
#  Run once (as Administrator) to register the 15-minute
#  background notification task in Windows Task Scheduler.
# ===================================================================

param(
    [switch]$Uninstall,
    [int]$IntervalMinutes = 15
)

$TaskName  = "FocusFlow_Notifications"
$AppDir    = $PSScriptRoot
$NotifyPs1 = Join-Path $AppDir "notify.ps1"
$HtmlFile  = Join-Path $AppDir "index.html"

Write-Host ""
Write-Host "  +-------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  FocusFlow - Notification Scheduler Setup |" -ForegroundColor Cyan
Write-Host "  |  Fires every $IntervalMinutes minutes, even browser closed  |" -ForegroundColor Cyan
Write-Host "  +-------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ── Uninstall ──
if ($Uninstall) {
    Write-Host "  >> Removing FocusFlow notification task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "  [OK] Notification task removed." -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ── Validate files ──
if (-not (Test-Path $NotifyPs1)) {
    Write-Host "  [ERROR] notify.ps1 not found at: $NotifyPs1" -ForegroundColor Red
    exit 1
}
if (-not (Test-Path $HtmlFile)) {
    Write-Host "  [ERROR] index.html not found at: $HtmlFile" -ForegroundColor Red
    exit 1
}

Write-Host "  [OK] notify.ps1  found: $NotifyPs1" -ForegroundColor Green
Write-Host "  [OK] index.html  found: $HtmlFile"  -ForegroundColor Green
Write-Host ""

# ── Build action: run notify.ps1 silently every N minutes ──
$psExe  = "powershell.exe"
$psArgs = "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File `"$NotifyPs1`""

$action = New-ScheduledTaskAction -Execute $psExe -Argument $psArgs

# ── Trigger: repeat every 15 min, starting at next round 15-min boundary, daily ──
$startTime = (Get-Date).Date.AddHours((Get-Date).Hour + 1)  # next clean hour
$trigger   = New-ScheduledTaskTrigger -Once `
               -At $startTime `
               -RepetitionInterval  (New-TimeSpan -Minutes $IntervalMinutes) `
               -RepetitionDuration  (New-TimeSpan -Hours 16)   # 16-hour window per day

# ── Settings: run even if on battery, don't stop if idle ──
$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -ExecutionTimeLimit  (New-TimeSpan -Minutes 2) `
    -MultipleInstances   IgnoreNew `
    -RunOnlyIfNetworkAvailable $false

# ── Principal: current user, interactive (needed for toast UI) ──
$principal = New-ScheduledTaskPrincipal `
    -UserId    "$env:USERDOMAIN\$env:USERNAME" `
    -LogonType Interactive `
    -RunLevel  Limited

# ── Remove existing task if present ──
$existing = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "  >> Updating existing notification task..." -ForegroundColor Yellow
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# ── Register ──
Register-ScheduledTask `
    -TaskName    $TaskName `
    -Action      $action `
    -Trigger     $trigger `
    -Settings    $settings `
    -Principal   $principal `
    -Description "FocusFlow -- Fires a Windows toast notification every $IntervalMinutes minutes with your pending tasks." `
    | Out-Null

Write-Host "  [OK] Notification task registered!" -ForegroundColor Green
Write-Host ""
Write-Host "  What this does:" -ForegroundColor Cyan
Write-Host "     - Every $IntervalMinutes minutes a native Windows toast pops OVER your current app." -ForegroundColor Gray
Write-Host "     - Shows how many tasks are done vs pending." -ForegroundColor Gray
Write-Host "     - Lists your top pending tasks by priority." -ForegroundColor Gray
Write-Host "     - Clicking the notification re-opens FocusFlow in your browser." -ForegroundColor Gray
Write-Host "     - Works even when the browser is closed." -ForegroundColor Gray
Write-Host ""
Write-Host "  [NOTE] FocusFlow must write state.json at least once today." -ForegroundColor Yellow
Write-Host "         Open index.html and click 'Lock in my tasks' to generate it." -ForegroundColor Gray
Write-Host ""
Write-Host "  To uninstall: .\setup-notifications.ps1 -Uninstall" -ForegroundColor Yellow
Write-Host ""

# ── Test fire immediately ──
$test = Read-Host "  Run a test notification right now? (y/n)"
if ($test -match '^[Yy]') {
    Write-Host "  >> Firing test notification..." -ForegroundColor Cyan
    & powershell.exe -WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File "$NotifyPs1"
    Write-Host "  [OK] Test fired. Check your notification tray." -ForegroundColor Green
}

Write-Host ""
