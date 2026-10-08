# ===================================================================
#  FocusFlow - State Bridge (local HTTP server)
#  Listens on http://localhost:27182 and writes state.json to disk
#  whenever FocusFlow POSTs its state from the browser.
#
#  Start once at login (install.ps1 already handles this).
#  Runs silently in the background.
# ===================================================================

$AppDir    = $PSScriptRoot
$StateFile = Join-Path $AppDir "state.json"
$Port      = 27182
$Prefix    = "http://localhost:$Port/"

# Only one instance
$mutex = New-Object System.Threading.Mutex($false, "FocusFlowBridge")
if (-not $mutex.WaitOne(0)) {
    exit 0   # already running
}

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($Prefix)

try {
    $listener.Start()
} catch {
    exit 1
}

while ($listener.IsListening) {
    try {
        $ctx      = $listener.GetContext()
        $req      = $ctx.Request
        $resp     = $ctx.Response

        # CORS headers so the browser page can POST
        $resp.Headers.Add("Access-Control-Allow-Origin",  "*")
        $resp.Headers.Add("Access-Control-Allow-Methods", "POST, OPTIONS")
        $resp.Headers.Add("Access-Control-Allow-Headers", "Content-Type")

        if ($req.HttpMethod -eq "OPTIONS") {
            $resp.StatusCode = 204
            $resp.Close()
            continue
        }

        if ($req.HttpMethod -eq "POST" -and $req.Url.AbsolutePath -eq "/state") {
            $reader  = New-Object System.IO.StreamReader($req.InputStream)
            $body    = $reader.ReadToEnd()
            $reader.Close()
            [System.IO.File]::WriteAllText($StateFile, $body, [System.Text.Encoding]::UTF8)
            $resp.StatusCode = 200
            $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}')
            $resp.ContentLength64 = $bytes.Length
            $resp.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $resp.StatusCode = 404
        }

        $resp.Close()
    } catch { }
}
