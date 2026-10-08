#!/usr/bin/env node
/**
 * FocusFlow Launcher
 * ──────────────────
 * This script is triggered at Windows startup (via Task Scheduler).
 * It opens the FocusFlow UI in the default browser.
 *
 * Usage: node focusflow.js
 */

'use strict';

const path   = require('path');
const { exec } = require('child_process');
const fs     = require('fs');

const htmlFile = path.join(__dirname, 'index.html');

if (!fs.existsSync(htmlFile)) {
  console.error('[FocusFlow] ERROR: index.html not found at', htmlFile);
  process.exit(1);
}

// Build a file:// URL
const fileUrl = 'file:///' + htmlFile.replace(/\\/g, '/');

console.log('[FocusFlow] Opening:', fileUrl);

// Open in default browser (Windows)
exec(`start "" "${fileUrl}"`, (err) => {
  if (err) {
    console.error('[FocusFlow] Could not open browser:', err.message);
  } else {
    console.log('[FocusFlow] Browser launched. Have a productive day! 🎯');
  }
});
