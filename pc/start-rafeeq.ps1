# Starts what رفيق (Masar's mentor) needs on this PC:
#   LM Studio with Qwen3.5-9B (shared with هاشمي, loaded once and never reloaded here),
#   رفيق's own token gate, rafeeq-proxy.mjs (:8788) and its own Cloudflare tunnel ("masar").
# Leaves everything of هاشمي's alone: its gate (:8787), its tunnel and its indexer.
# Run at Windows sign-in by the "Rafeeq" scheduled task; safe to run again.
# Logs: pc\logs\*.log

$ErrorActionPreference = 'Continue'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$logs = Join-Path $here 'logs'
New-Item -ItemType Directory -Force $logs | Out-Null
$lms = Join-Path $env:USERPROFILE '.lmstudio\bin\lms.exe'
$cloudflared = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
$node = (Get-Command node -ErrorAction Stop).Source
$tunnelConfig = Join-Path $here 'cloudflared.yml'

function Log($msg) { "$(Get-Date -Format s) $msg" | Add-Content (Join-Path $logs 'start.log') -Encoding utf8 }

function Running($pattern) {
  [bool](Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -and $_.CommandLine -like $pattern })
}

function Start-Hidden($name, $file, $arguments, $workdir, $pattern) {
  if (Running $pattern) { Log "$name already running"; return }
  Start-Process -FilePath $file -ArgumentList $arguments -WorkingDirectory $workdir -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $logs "$name.log") -RedirectStandardError (Join-Path $logs "$name.err.log")
  Log "$name started"
}

Log 'starting'

if (-not (Test-Path (Join-Path $here '.env'))) { Log 'pc\.env is missing: see pc\README.md'; exit 1 }
if (-not (Test-Path $tunnelConfig)) { Log 'pc\cloudflared.yml is missing: see pc\README.md'; exit 1 }

# 1. LM Studio: start the server and load the model only if هاشمي's script hasn't already.
#    Same settings as هاشمي (8k context, one at a time), so the GPU holds a single copy.
& $lms server start --port 1234 *>> (Join-Path $logs 'lms.log')
$loaded = (& $lms ps 2>&1) -join "`n"
if ($loaded -notmatch 'qwen/qwen3.5-9b') {
  & $lms load qwen/qwen3.5-9b -c 8192 --gpu max --parallel 1 --identifier qwen/qwen3.5-9b -y *>> (Join-Path $logs 'lms.log')
}
Log 'LM Studio ready'

# 2. رفيق's gate and tunnel. The names must never match هاشمي's patterns
#    ('*node*gate.mjs*', '*cloudflared*tunnel run hashmi*'), or his script would skip starting his.
Start-Hidden 'rafeeq-proxy' $node @('rafeeq-proxy.mjs') $here '*node*rafeeq-proxy.mjs*'
Start-Hidden 'rafeeq-tunnel' $cloudflared @('tunnel', '--config', $tunnelConfig, 'run', 'masar') $here '*cloudflared*run masar*'
Log 'all started'
