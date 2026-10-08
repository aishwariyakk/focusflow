# 🎯 FocusFlow — AI-Assisted Daily Momentum Tracker

<div align="center">

![FocusFlow Banner](https://img.shields.io/badge/FocusFlow-Daily%20Momentum%20Tracker-6c63ff?style=for-the-badge&logo=target&logoColor=white)

[![Built with IBM Bob](https://img.shields.io/badge/Built%20with-IBM%20Bob%20AI-0f62fe?style=flat-square&logo=ibm&logoColor=white)](https://www.ibm.com/products/bob)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%2F11-0078d4?style=flat-square&logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Tech](https://img.shields.io/badge/Stack-HTML%20%7C%20CSS%20%7C%20JS%20%7C%20PowerShell-f9ca24?style=flat-square)](.)
[![License](https://img.shields.io/badge/License-MIT-43e97b?style=flat-square)](LICENSE)
[![No Dependencies](https://img.shields.io/badge/Dependencies-Zero-ff6584?style=flat-square)](.)

> **Stay on track, every 15 minutes.**  
> Native Windows toast notifications. Zero cloud dependencies. One HTML file.

</div>

---

## 🤖 Built with AI — IBM Bob

This project was **designed, architected, and built end-to-end using [IBM Bob](https://www.ibm.com/products/bob)**, IBM's AI software engineering assistant. It demonstrates practical use of AI in daily productivity tooling.

### How AI was used in this project

| Phase | AI Contribution |
|---|---|
| **Architecture** | Bob designed the 3-process Windows Task Scheduler architecture (browser opener → state bridge → notifier) |
| **UI/UX Design** | Bob generated the full single-file HTML/CSS app with dark/light themes, progress rings, heatmap, and Pomodoro timer |
| **PowerShell scripting** | Bob wrote `bridge.ps1` (local HTTP server), `notify.ps1` (WinRT toast engine with 4-method fallback chain), and `install.ps1` (Task Scheduler registration) |
| **Notification engine** | Bob identified and implemented the `Microsoft.Windows.Explorer` AppID trick to bypass Focus Assist / Do Not Disturb |
| **Debugging** | Bob diagnosed and fixed cross-process state sync issues between the browser tab and the notification daemon |
| **Documentation** | Bob authored this README, inline comments, and the install/troubleshooting guide |

> 💡 **Key takeaway:** A complete, production-quality Windows desktop productivity agent — with a local HTTP bridge, native OS notifications, persistent state, and a polished UI — was built in a single session using AI-assisted engineering. No external runtime, no npm, no cloud.

---

## ✨ Features

| Feature | Details |
|---|---|
| 🧠 **AI-assisted architecture** | Designed with IBM Bob — see above |
| 🔔 **Native Windows toasts** | Uses `Microsoft.Windows.Explorer` AppID — bypasses Focus Assist / Do Not Disturb; stays on screen until dismissed |
| ⏰ **15-minute reminders** | Fires via Windows Task Scheduler even when the browser is **completely closed** |
| 📋 **Daily task setup** | 9 pre-filled daily habits + unlimited custom tasks with High/Med/Low priority |
| ✅ **Task completion tracking** | Check off tasks from any reminder; completed tasks show green shimmer |
| 📊 **Progress ring** | SVG ring + gradient bar show real-time % completion |
| 🔥 **Streak tracker** | 7-day dot indicator + consecutive day-streak counter |
| 🗓️ **7-week heatmap** | Completion heat map across the last 49 days |
| 🍅 **Pomodoro timer** | Built-in 25-min focus timer with visual ring countdown |
| 🔁 **Recurring tasks** | Daily / Weekly (with optional "2nd Monday") / Monthly (by date or weekday) |
| 😊 **Mood check-in** | Set your energy level at the start of each day |
| 🌙 **Dark + Light themes** | Toggle at any time |
| 💤 **Snooze** | Delay next reminder by 5 minutes |
| 🎉 **Celebration screen** | Confetti + fanfare when every task is done |
| 🔊 **Sound effects** | Subtle audio cues via Web Audio API (no audio files) |
| 🚫 **No cloud, no Node.js** | Pure HTML/CSS/JS + PowerShell — zero dependencies beyond Windows |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Windows Task Scheduler                                 │
│  ┌──────────────────────────────────────────────────┐  │
│  │ FocusFlow_OpenBrowser  (at login)                │  │
│  │  → opens index.html in default browser           │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ FocusFlow_Bridge       (at login, background)    │  │
│  │  → bridge.ps1   listens on localhost:27182        │  │
│  │  → receives POSTed state from browser tab        │  │
│  │  → writes state.json to disk                     │  │
│  └──────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────┐  │
│  │ FocusFlow_Notifications (every 15 min)           │  │
│  │  → notify.ps1   reads state.json from disk       │  │
│  │  → shows WinRT toast via Explorer AppID          │  │
│  │  → 4-method fallback chain if WinRT unavailable  │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
           ↑ writes via HTTP POST    ↑ reads directly
    ┌─────────────┐            ┌───────────┐
    │  index.html │──────────▶ │ state.json│
    │  (browser)  │            │  (disk)   │
    └─────────────┘            └───────────┘
```

**Key design choices:**
- `index.html` POSTs state to the bridge every time a task is checked or locked in — no file system access from the browser.
- `notify.ps1` reads `state.json` directly from disk — **no browser required** for notifications.
- `Microsoft.Windows.Explorer` AppID gives toasts the highest possible priority on Windows 10/11, overriding Focus Assist and Do Not Disturb.
- `scenario="alarm" duration="long"` keeps the notification on screen until the user dismisses it.

---

## 📁 File Structure

```
focusflow/
├── index.html               ← Complete app UI (self-contained, ~1,200 lines)
├── bridge.ps1               ← Local HTTP server (localhost:27182); writes state.json
├── notify.ps1               ← Notification engine; 4-method WinRT fallback chain
├── install.ps1              ← Full installer; registers 3 Windows Scheduled Tasks
├── setup-notifications.ps1  ← Notifications-only installer (advanced use)
├── focusflow.js             ← Node.js launcher (alternative startup method)
├── state.json               ← Runtime task state (git-ignored)
├── notify.log               ← Notification run log (git-ignored)
└── README.md                ← This file
```

---

## 🚀 Quick Start

### Option A — Just open the file (no install, reminders in-browser only)

Double-click `index.html` in File Explorer. Done.

The browser-side countdown fires in-app reminders every 15 minutes while the tab is open.

### Option B — Full install (recommended — native toasts even when browser is closed)

**Step 1 — Open PowerShell as Administrator**

Press `Win + X` → "Windows PowerShell (Admin)"

**Step 2 — Navigate to the FocusFlow folder**

```powershell
cd "C:\path\to\focusflow"
```

**Step 3 — Set execution policy (one-time)**

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

**Step 4 — Run the installer**

```powershell
.\install.ps1
```

The installer will:
1. Validate all required files exist
2. Register 3 Windows Scheduled Tasks
3. Optionally start the bridge immediately
4. Optionally open FocusFlow right now

**Step 5 — Lock in your tasks**

Pick your tasks and click **"Lock in my tasks & Start FocusFlow"**. Native notifications will fire every 15 minutes from this point.

### Uninstall

```powershell
.\install.ps1 -Uninstall
```

---

## 📅 Day-by-Day Flow

### Morning setup (first open of the day)

1. FocusFlow opens automatically at login
2. **Mood check-in** — pick your energy level
3. **Daily defaults** — 9 pre-filled habits; uncheck or delete any you don't want
4. **Custom tasks** — add your own with priority tags
5. Click **"Lock in my tasks & Start FocusFlow"**

### Every 15 minutes

- A **native Windows toast** fires over your current window
- The browser tab (if open) also transitions to the Reminder screen
- Shows: reminder number, % complete, progress ring, pending tasks
- Check off done tasks, use the Pomodoro timer, add quick tasks, or snooze

### End of day

- All tasks done → **celebration screen** with confetti
- Streak and heatmap update automatically
- Tomorrow: fresh setup screen at next login

---

## 🔔 Notification Fallback Chain

`notify.ps1` tries 4 methods in order, logging each attempt to `notify.log`:

| # | Method | Notes |
|---|---|---|
| 1 | **WinRT toast — Explorer AppID** | Highest priority; bypasses Focus Assist; persistent |
| 2 | **WinRT toast — PowerShell AppID** | Standard toast; may be suppressed by Focus Assist |
| 3 | **WScript.Shell Popup** | Modal dialog; auto-closes after 20 s |
| 4 | **msg.exe** | Direct Windows message; always visible |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Pure HTML5 + CSS3 + Vanilla JS — zero npm, zero CDN, zero build step |
| Persistence | `localStorage` (primary) + `state.json` on disk (cross-process reads) |
| Bridge | PowerShell `System.Net.HttpListener` on `localhost:27182` |
| Notifications | Windows Runtime (WinRT) `ToastNotificationManager` via PowerShell reflection |
| Scheduler | Windows Task Scheduler via `Register-ScheduledTask` |
| Sounds | Web Audio API oscillator — no audio files |
| AI Tooling | IBM Bob (design, code generation, debugging, documentation) |

---

## 📋 Requirements

- Windows 10 version 1903 or later (Windows 11 fully supported)
- Any modern browser (Chrome, Edge, Firefox)
- PowerShell 5.1 (built into Windows — no install needed)
- No internet connection required
- No Node.js, Python, or any runtime required

---

## 🔧 Troubleshooting

### Toasts not appearing

```powershell
# Check the log
Get-Content .\notify.log -Tail 20

# Test the notifier directly
powershell -ExecutionPolicy Bypass -File ".\notify.ps1"

# Verify the scheduled task
Get-ScheduledTask -TaskName "FocusFlow_Notifications" | Get-ScheduledTaskInfo
```

### Bridge not connecting (yellow status in app)

```powershell
# Start manually
Start-Process powershell -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PWD\bridge.ps1`""

# Test it
Invoke-WebRequest -Uri http://localhost:27182/state -Method POST -Body '{"test":true}' -ContentType application/json
```

### Execution policy error

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
```

---

## 📄 License

MIT © 2025 — see [LICENSE](LICENSE)

---

<div align="center">

**FocusFlow** — Built with [IBM Bob AI](https://www.ibm.com/products/bob) · Pure PowerShell + Vanilla Web · No cloud · No telemetry · Just focus.

*A demonstration of AI-assisted software engineering for real daily productivity workflows.*

</div>
