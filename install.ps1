# ===================================================================
#  FocusFlow -- Full Installer
#  1) Registers at-login task: opens FocusFlow in browser
#  2) Registers at-login task: starts bridge.ps1 (state sync)
#  3) Registers repeat task:   fires native notification every 30 min
# ===================================================================

param(
    [switch]$Uninstall
)

$AppDir      = $PSScriptRoot
$IndexHtml   = Join-Path $AppDir "index.html"
$BridgePs1   = Join-Path $AppDir "bridge.ps1"
$NotifyPs1   = Join-Path $AppDir "notify.ps1"

$TaskBrowser = "FocusFlow_OpenBrowser"
$TaskBridge  = "FocusFlow_Bridge"
$TaskNotify  = "FocusFlow_Notifications"

Write-Host ""
Write-Host "  +-----------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |   FocusFlow -- Full Installer                 |" -ForegroundColor Cyan
Write-Host "  |   Browser opener + State bridge + Notifier   |" -ForegroundColor Cyan
Write-Host "  +-----------------------------------------------+" -ForegroundColor Cyan
Write-Host ""

# ── Uninstall ──
if ($Uninstall) {
    Write-Host "  >> Removing all FocusFlow tasks..." -ForegroundColor Yellow
    foreach ($t in @($TaskBrowser, $TaskBridge, $TaskNotify)) {
        Unregister-ScheduledTask -TaskName $t -Confirm:$false -ErrorAction SilentlyContinue
        Write-Host "     Removed: $t" -ForegroundColor Gray
    }
    Write-Host "  [OK] FocusFlow fully uninstalled." -ForegroundColor Green
    Write-Host ""
    exit 0
}

# ── Validate files ──
foreach ($f in @($IndexHtml, $BridgePs1, $NotifyPs1)) {
    if (-not (Test-Path $f)) {
        Write-Host "  [ERROR] Missing: $f" -ForegroundColor Red
        Write-Host "          Make sure all FocusFlow files are in the same folder." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "  [OK] Found: $(Split-Path $f -Leaf)" -ForegroundColor Green
}
Write-Host ""

$psExe = "powershell.exe"

# ────────────────────────────────────────────────────
#  TASK 1: Open FocusFlow in browser at login
# ────────────────────────────────────────────────────
$action1   = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start `"`" `"$IndexHtml`""
$trigger1  = New-ScheduledTaskTrigger -AtLogOn
$settings1 = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew
$prin1     = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Unregister-ScheduledTask -TaskName $TaskBrowser -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskBrowser -Action $action1 -Trigger $trigger1 -Settings $settings1 -Principal $prin1 -Description "FocusFlow -- Opens browser at login" | Out-Null
Write-Host "  [OK] Task registered: Browser opens at login" -ForegroundColor Green

# ────────────────────────────────────────────────────
#  TASK 2: Start bridge.ps1 at login (hidden window)
#          Bridge listens on localhost:27182, writes state.json
# ────────────────────────────────────────────────────
$bridgeArgs = "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File `"$BridgePs1`""
$action2    = New-ScheduledTaskAction -Execute $psExe -Argument $bridgeArgs
$trigger2   = New-ScheduledTaskTrigger -AtLogOn
$settings2  = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 20) -MultipleInstances IgnoreNew
$prin2      = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Unregister-ScheduledTask -TaskName $TaskBridge -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskBridge -Action $action2 -Trigger $trigger2 -Settings $settings2 -Principal $prin2 -Description "FocusFlow -- State bridge (listens localhost:27182)" | Out-Null
Write-Host "  [OK] Task registered: State bridge starts at login" -ForegroundColor Green

# ────────────────────────────────────────────────────
#  TASK 3: Fire notify.ps1 every 30 minutes
#          Shows native Windows toast over any foreground app
# ────────────────────────────────────────────────────
$notifyArgs = "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File `"$NotifyPs1`""
$action3    = New-ScheduledTaskAction -Execute $psExe -Argument $notifyArgs
$startTime  = (Get-Date).Date.AddHours((Get-Date).Hour + 1)
$trigger3   = New-ScheduledTaskTrigger -Once -At $startTime `
                -RepetitionInterval (New-TimeSpan -Minutes 30) `
                -RepetitionDuration (New-TimeSpan -Hours 18)
$settings3  = New-ScheduledTaskSettingsSet -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Minutes 2) -MultipleInstances IgnoreNew
$prin3      = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive -RunLevel Limited
Unregister-ScheduledTask -TaskName $TaskNotify -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $TaskNotify -Action $action3 -Trigger $trigger3 -Settings $settings3 -Principal $prin3 -Description "FocusFlow -- Native toast notification every 30 min" | Out-Null
Write-Host "  [OK] Task registered: Notifications every 30 min" -ForegroundColor Green

Write-Host ""
Write-Host "  All 3 tasks installed!" -ForegroundColor Cyan
Write-Host ""
Write-Host "  How it works:" -ForegroundColor Cyan
Write-Host "     1. At login: FocusFlow opens in your browser." -ForegroundColor Gray
Write-Host "     2. At login: A silent bridge starts (localhost:27182)." -ForegroundColor Gray
Write-Host "     3. Every time you check/add a task in FocusFlow, state is" -ForegroundColor Gray
Write-Host "        saved to state.json via the bridge." -ForegroundColor Gray
Write-Host "     4. Every 15 min: a native Windows toast pops over your current" -ForegroundColor Gray
Write-Host "        app showing pending tasks and % complete." -ForegroundColor Gray
Write-Host "     5. Works even if FocusFlow browser tab is closed." -ForegroundColor Gray
Write-Host ""
Write-Host "  To uninstall: .\install.ps1 -Uninstall" -ForegroundColor Yellow
Write-Host ""

# ── Start bridge now (no reboot needed) ──
$startBridge = Read-Host "  Start the bridge now (needed for notifications to work today)? (y/n)"
if ($startBridge -match '^[Yy]') {
    Start-Process $psExe -ArgumentList "-WindowStyle Hidden -NonInteractive -ExecutionPolicy Bypass -File `"$BridgePs1`"" -WindowStyle Hidden
    Write-Host "  [OK] Bridge started on localhost:27182" -ForegroundColor Green
}

# ── Open FocusFlow now ──
$openNow = Read-Host "  Open FocusFlow in browser now? (y/n)"
if ($openNow -match '^[Yy]') {
    Start-Process $IndexHtml
    Write-Host "  [*] FocusFlow launched! Lock in your tasks to activate notifications." -ForegroundColor Green
}

Write-Host ""
