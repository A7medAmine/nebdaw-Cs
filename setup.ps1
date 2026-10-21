<#
Python Dev setup for Windows.
Installs Python 3 if needed, makes sure it is on PATH and installs common libraries
into the same Python that "python" runs.

  setup.bat            interactive (double-click works)
  setup.bat -Yes       accept defaults (core + dev libraries)
  setup.bat -All       install every library group
#>
param(
    [switch]$Yes,
    [switch]$All
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$PyVersion = '3.13.17'
$MinMinor = 10
$LogFile = Join-Path $env:TEMP 'python-dev-setup.log'

$Core = @('numpy', 'pandas', 'matplotlib', 'requests', 'rich', 'pillow', 'python-dotenv', 'tqdm', 'ipython')
$Data = @('scipy', 'scikit-learn', 'seaborn', 'jupyterlab', 'openpyxl')
$Web = @('flask', 'fastapi', 'uvicorn[standard]', 'httpx', 'beautifulsoup4')
$Dev = @('pytest', 'ruff', 'mypy')
$VSCodeExtensions = @('ms-python.python', 'ms-python.vscode-pylance', 'ms-python.debugpy', 'charliermarsh.ruff')

if ($All) { $Yes = $true }

# ---------- look ----------
$script:Step = 0
$Interactive = -not [Console]::IsOutputRedirected
$TotalSteps = 5

function Write-Banner {
    Write-Host ''
    Write-Host '  +------------------------------------------+' -ForegroundColor Cyan
    Write-Host '  |          Python Dev  -  Setup            |' -ForegroundColor Cyan
    Write-Host '  |  Python + PATH + libraries, one command  |' -ForegroundColor Cyan
    Write-Host '  +------------------------------------------+' -ForegroundColor Cyan
    Write-Host "  Log file: $LogFile" -ForegroundColor DarkGray
}

function Write-Step([string]$Text) {
    $script:Step++
    Write-Host ''
    Write-Host "[$script:Step/$TotalSteps] " -ForegroundColor Blue -NoNewline
    Write-Host $Text -ForegroundColor White
}

function Write-Ok([string]$Text) { Write-Host '  [ok] ' -ForegroundColor Green -NoNewline; Write-Host $Text }
function Write-Bad([string]$Text) { Write-Host '  [x]  ' -ForegroundColor Red -NoNewline; Write-Host $Text }
function Write-Warn([string]$Text) { Write-Host '  [!]  ' -ForegroundColor Yellow -NoNewline; Write-Host $Text }
function Write-Info([string]$Text) { Write-Host "  $Text" -ForegroundColor DarkGray }

function Stop-Setup([string]$Text) {
    Write-Bad $Text
    Write-Host "  See the log: $LogFile" -ForegroundColor DarkGray
    Write-Host ''
    exit 1
}

function Join-Arguments([string[]]$Arguments) {
    ($Arguments | ForEach-Object {
        if ($_ -match '[\s"]') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join ' '
}

# Run a program with a spinner; output goes to the log. Returns $true on success.
function Invoke-Spin([string]$Message, [string]$FilePath, [string[]]$Arguments) {
    $out = [IO.Path]::GetTempFileName()
    $err = [IO.Path]::GetTempFileName()
    Add-Content -Path $LogFile -Value "`r`n> $FilePath $(Join-Arguments $Arguments)"
    try {
        $proc = Start-Process -FilePath $FilePath -ArgumentList (Join-Arguments $Arguments) -NoNewWindow -PassThru `
            -RedirectStandardOutput $out -RedirectStandardError $err
    } catch {
        Add-Content -Path $LogFile -Value $_.Exception.Message
        Write-Bad $Message
        return $false
    }
    $null = $proc.Handle
    if ($Interactive) {
        $width = try { [Console]::BufferWidth - 1 } catch { 79 }
        $shown = if ($Message.Length -gt $width - 4) { $Message.Substring(0, $width - 7) + '...' } else { $Message }
        $frames = '|', '/', '-', '\'
        $i = 0
        while (-not $proc.HasExited) {
            Write-Host ("`r  " + $frames[$i % 4] + ' ' + $shown) -ForegroundColor Cyan -NoNewline
            $i++
            Start-Sleep -Milliseconds 100
        }
        Write-Host ("`r" + (' ' * $width) + "`r") -NoNewline
    }
    $proc.WaitForExit()
    Get-Content $out, $err -ErrorAction SilentlyContinue | Add-Content -Path $LogFile
    Remove-Item $out, $err -ErrorAction SilentlyContinue
    if ($proc.ExitCode -eq 0) { Write-Ok $Message; return $true }
    Write-Bad $Message
    return $false
}

function Get-Bar([int]$Current, [int]$Total) {
    $width = 24
    $filled = [int][Math]::Floor($Current * $width / $Total)
    ('#' * $filled) + ('-' * ($width - $filled)) + ' ' + ('{0,2}/{1}' -f $Current, $Total)
}

function Read-YesNo([string]$Question, [bool]$Default) {
    if ($Yes) { return $Default }
    $hint = if ($Default) { 'Y/n' } else { 'y/N' }
    Write-Host '  ? ' -ForegroundColor White -NoNewline
    $answer = Read-Host "$Question [$hint]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer -match '^[Yy]'
}

# ---------- python ----------
function Test-Python([string]$Exe, [string[]]$PreArgs = @()) {
    try {
        $code = "import sys; print(sys.executable) if sys.version_info >= (3, $MinMinor) else sys.exit(1)"
        $result = & $Exe @PreArgs -c $code 2>$null
        if ($LASTEXITCODE -eq 0 -and $result) { return ($result | Select-Object -Last 1).Trim() }
    } catch { }
    return $null
}

# Prefer the "python" that PATH already runs, so the libraries land where the user will look.
function Find-Python {
    foreach ($name in 'python', 'python3') {
        $found = Test-Python $name
        if ($found) { return $found }
    }
    $found = Test-Python 'py' @('-3')
    if ($found) { return $found }
    $dirs = @("$env:LOCALAPPDATA\Programs\Python", "$env:ProgramFiles")
    foreach ($exe in Get-ChildItem -Path $dirs -Filter 'python.exe' -Recurse -Depth 1 -ErrorAction SilentlyContinue |
            Where-Object { $_.Directory.Name -like 'Python3*' } | Sort-Object FullName -Descending) {
        $found = Test-Python $exe.FullName
        if ($found) { return $found }
    }
    return $null
}

function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$user;$machine"
}

function Install-Python {
    $short = ($PyVersion -split '\.')[0..1] -join '.'
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $override = '/quiet InstallAllUsers=0 PrependPath=1 Include_launcher=1 Include_test=0'
        $ok = Invoke-Spin "Installing Python $short with winget" 'winget' @(
            'install', '-e', '--id', "Python.Python.$short", '--scope', 'user', '--silent',
            '--accept-package-agreements', '--accept-source-agreements', '--override', $override)
        if ($ok) { Update-SessionPath; return }
        Write-Warn 'winget failed, downloading the installer from python.org instead'
    }
    $arch = if ($env:PROCESSOR_ARCHITECTURE -eq 'ARM64') { 'arm64' } else { 'amd64' }
    $url = "https://www.python.org/ftp/python/$PyVersion/python-$PyVersion-$arch.exe"
    $installer = Join-Path $env:TEMP "python-$PyVersion-$arch.exe"
    Write-Host "  Downloading Python $PyVersion ..." -ForegroundColor Cyan -NoNewline
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing
        Write-Host "`r" -NoNewline
        Write-Ok "Downloaded Python $PyVersion"
    } catch {
        Write-Host ''
        Stop-Setup "Download failed: $($_.Exception.Message)"
    }
    $ok = Invoke-Spin "Installing Python $PyVersion" $installer @(
        '/quiet', 'InstallAllUsers=0', 'PrependPath=1', 'Include_launcher=1', 'Include_test=0')
    if (-not $ok) { Stop-Setup 'The Python installer failed' }
    Update-SessionPath
}

# ---------- PATH ----------
function Test-OnPath([string]$Dir) {
    $target = $Dir.TrimEnd('\')
    $all = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User')
    return [bool]($all -split ';' | Where-Object { $_ -and $_.TrimEnd('\') -eq $target })
}

# Edit the raw registry value so %VARIABLES% in the user PATH are kept unexpanded.
function Add-UserPath([string]$Dir) {
    $raw = (Get-Item 'HKCU:\Environment').GetValue('Path', '', 'DoNotExpandEnvironmentNames')
    $value = if ($raw) { "$Dir;$raw" } else { $Dir }
    Set-ItemProperty -Path 'HKCU:\Environment' -Name 'Path' -Value $value -Type ExpandString
    $env:Path = "$Dir;$env:Path"
}

# Tell Explorer the environment changed so new terminals see the new PATH without a sign-out.
function Send-EnvironmentChange {
    if (-not ('Win32.NativeMethods' -as [type])) {
        Add-Type -Namespace Win32 -Name NativeMethods -MemberDefinition @'
[DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam,
    uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
'@
    }
    $result = [UIntPtr]::Zero
    [void][Win32.NativeMethods]::SendMessageTimeout([IntPtr]0xffff, 0x1A, [UIntPtr]::Zero, 'Environment', 2, 5000, [ref]$result)
}

function Get-PythonPath([string]$Python, [string]$Code) {
    return (& $Python -c $Code 2>$null | Select-Object -Last 1)
}

# ---------- libraries ----------
function Select-Packages {
    if ($All) { return @($Core + $Data + $Web + $Dev) }
    Write-Host '  Library groups' -ForegroundColor White
    Write-Host '    core ' -ForegroundColor Cyan -NoNewline; Write-Host ($Core -join ' ')
    Write-Host '    data ' -ForegroundColor Cyan -NoNewline; Write-Host ($Data -join ' ')
    Write-Host '    web  ' -ForegroundColor Cyan -NoNewline; Write-Host ($Web -join ' ')
    Write-Host '    dev  ' -ForegroundColor Cyan -NoNewline; Write-Host ($Dev -join ' ')
    Write-Host ''
    $list = @()
    if (Read-YesNo 'Install core libraries?' $true) { $list += $Core }
    if (Read-YesNo 'Install data science libraries?' $false) { $list += $Data }
    if (Read-YesNo 'Install web libraries?' $false) { $list += $Web }
    if (Read-YesNo 'Install dev tools?' $true) { $list += $Dev }
    return $list
}

# ---------- main ----------
Set-Content -Path $LogFile -Value "Python Dev setup $(Get-Date -Format s)"
Write-Banner

Write-Step 'Checking Python'
$python = Find-Python
if ($python) {
    Write-Ok "Found $(& $python --version 2>&1) at $python"
} else {
    Write-Warn "Python 3.$MinMinor+ not found, installing it"
    Install-Python
    $python = Find-Python
    if (-not $python) { Stop-Setup 'Python was installed but could not be found. Open a new terminal and re-run.' }
    Write-Ok "Installed $(& $python --version 2>&1)"
}

Write-Step 'Preparing pip'
if (-not (Invoke-Spin 'Checking pip' $python @('-m', 'pip', '--version'))) {
    if (-not (Invoke-Spin 'Installing pip' $python @('-m', 'ensurepip', '--upgrade'))) { Stop-Setup 'Could not install pip' }
}
# Fall back to a per-user install when Python lives in a folder only admins can write to.
$siteWritable = (Get-PythonPath $python 'import os, sysconfig; print(os.access(sysconfig.get_paths()[''purelib''], os.W_OK))') -eq 'True'
$pipUser = if ($siteWritable) { @() } else { @('--user') }
if (-not $siteWritable) { Write-Info 'Python folder is read-only for you, libraries go to your user folder' }
if (-not (Invoke-Spin 'Upgrading pip' $python (@('-m', 'pip', 'install', '--upgrade', '--disable-pip-version-check') + $pipUser + 'pip'))) {
    Write-Warn 'pip upgrade failed, continuing'
}

Write-Step 'Adding Python to PATH'
$pyDir = Split-Path $python
$dirs = @($pyDir, (Join-Path $pyDir 'Scripts'))
if (-not $siteWritable) { $dirs += Get-PythonPath $python 'import os, sysconfig; print(sysconfig.get_path(''scripts'', os.name + ''_user''))' }
$changed = $false
foreach ($dir in $dirs) {
    if (Test-OnPath $dir) { Write-Ok "Already on PATH: $dir" } else { Add-UserPath $dir; $changed = $true; Write-Ok "Added to PATH: $dir" }
}
if ($changed) { Send-EnvironmentChange }
$first = Test-Python 'python'
if ($first -and ($first -ne $python)) {
    Write-Warn "'python' currently opens $first, not $python."
    Write-Info 'Move the right folder to the top in System Properties > Environment Variables.'
}

Write-Step 'Installing libraries'
$packages = @(Select-Packages)
$failed = @()
if ($packages.Count -eq 0) {
    Write-Info 'No libraries selected'
} else {
    for ($i = 0; $i -lt $packages.Count; $i++) {
        $pkg = $packages[$i]
        $label = "$(Get-Bar ($i + 1) $packages.Count)  $pkg"
        if (-not (Invoke-Spin $label $python (@('-m', 'pip', 'install', '--upgrade', '--disable-pip-version-check') + $pipUser + $pkg))) {
            $failed += $pkg
        }
    }
}

Write-Step 'VS Code extensions'
$code = Get-Command code -ErrorAction SilentlyContinue
if ($code) {
    if (Read-YesNo 'Install Python extensions for VS Code?' $true) {
        foreach ($ext in $VSCodeExtensions) {
            if (-not (Invoke-Spin $ext $code.Source @('--install-extension', $ext, '--force'))) {
                Write-Warn "Could not install $ext"
            }
        }
    } else {
        Write-Info 'Skipped'
    }
} else {
    Write-Info "VS Code command 'code' not found, skipped"
}

# ---------- summary ----------
Write-Host ''
Write-Host '  +------------------------------------------+' -ForegroundColor Green
Write-Host '  |              Setup complete              |' -ForegroundColor Green
Write-Host '  +------------------------------------------+' -ForegroundColor Green
Write-Host "  Python       $(& $python --version 2>&1)"
Write-Host "  Location     $python"
Write-Host "  Libraries    $($packages.Count - $failed.Count) installed"
if ($failed.Count -gt 0) {
    Write-Host '  Failed       ' -ForegroundColor Red -NoNewline
    Write-Host ($failed -join ' ')
    Write-Info "Details in $LogFile"
}
Write-Host ''
Write-Host '  Next: ' -ForegroundColor White -NoNewline
Write-Host 'open a new terminal, then try'
Write-Host '    python -c "import sys; print(sys.executable)"' -ForegroundColor Cyan
Write-Host ''
