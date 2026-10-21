<#
Python Dev setup for Windows.
Installs Python 3 if needed, makes sure it is on PATH and installs common libraries
into the same Python that "python" runs. The libraries come from requirements.txt.
Then it installs the editor fonts and, if VS Code is installed, applies
python-dev.code-profile to it: extensions, settings, theme and snippets.

It asks no questions.

  setup.bat            double-click works too
  irm https://raw.githubusercontent.com/A7medAmine/nebdaw-Cs/main/setup.ps1 | iex

Everything runs inside one script block, so a piped run (irm | iex) leaves no
variables or settings behind in the user's PowerShell session.
#>

& {
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'

    $PyVersion = '3.13.17'
    $MinMinor = 10
    $LogFile = Join-Path $env:TEMP 'python-dev-setup.log'
    # Where repo files are downloaded from when the script runs without the repo
    # (irm ... | iex). NEBDAW_URL lets CI test a branch or commit.
    $RepoUrl = if ($env:NEBDAW_URL) { $env:NEBDAW_URL } else { 'https://raw.githubusercontent.com/A7medAmine/nebdaw-Cs/main' }
    # Empty when the script is piped into iex.
    $ScriptDir = $PSScriptRoot
    # Thrown by Stop-Setup; the main block catches it and stops without closing a piped session.
    $Stopped = 'Python Dev setup stopped'
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    # Retry and wait longer than pip's defaults so slow connections don't fail the install.
    $PipInstall = @('-m', 'pip', 'install', '--upgrade', '--disable-pip-version-check', '--retries', '5', '--timeout', '60')

    # Fonts the VS Code profile uses, from Google Fonts (OFL license), pinned to one commit.
    $FontUrl = 'https://raw.githubusercontent.com/google/fonts/45e3d5269e4a17d823f6d84470bc084dc5ae46f6/ofl'
    $Fonts = @(
        @{ Name = 'Cascadia Mono'; Files = @('cascadiamono/CascadiaMono[wght].ttf', 'cascadiamono/CascadiaMono-Italic[wght].ttf') },
        @{ Name = 'Noto Kufi Arabic'; Files = @('notokufiarabic/NotoKufiArabic[wght].ttf') }
    )

    # ---------- look ----------
    $Progress = @{ Step = 0 }
    $Interactive = -not [Console]::IsOutputRedirected
    $TotalSteps = 6

    function Write-Banner {
        Write-Host ''
        Write-Host '  +------------------------------------------+' -ForegroundColor Cyan
        Write-Host '  |          Python Dev  -  Setup            |' -ForegroundColor Cyan
        Write-Host '  |  Python, libraries, fonts and VS Code    |' -ForegroundColor Cyan
        Write-Host '  +------------------------------------------+' -ForegroundColor Cyan
        Write-Host "  Log file: $LogFile" -ForegroundColor DarkGray
    }

    function Write-Step([string]$Text) {
        $Progress.Step++
        Write-Host ''
        Write-Host "[$($Progress.Step)/$TotalSteps] " -ForegroundColor Blue -NoNewline
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
        throw $Stopped
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
    # requirements.txt next to this script, or the one on GitHub.
    function Get-RequirementsText {
        $local = if ($ScriptDir) { Join-Path $ScriptDir 'requirements.txt' }
        if ($local -and (Test-Path $local)) { return (Get-Content $local -Raw) }
        try {
            return (Invoke-RestMethod -Uri "$RepoUrl/requirements.txt" -UseBasicParsing)
        } catch {
            Add-Content -Path $LogFile -Value $_.Exception.Message
            Stop-Setup "Could not get the library list from $RepoUrl/requirements.txt"
        }
    }

    # One library per line in requirements.txt; blank lines and # comments are skipped.
    function Read-Packages {
        return @((Get-RequirementsText) -split "`r?`n" | ForEach-Object { ($_ -replace '#.*', '').Trim() } | Where-Object { $_ })
    }

    # A repo file: the copy next to this script, or a download from $RepoUrl.
    # Returns its path, or $null if it can't be had.
    function Get-RepoFile([string]$Name) {
        $local = if ($ScriptDir) { Join-Path $ScriptDir $Name }
        if ($local -and (Test-Path $local)) { return $local }
        $dest = Join-Path $env:TEMP "nebdaw-$Name"
        try {
            Invoke-WebRequest -Uri "$RepoUrl/$Name" -OutFile $dest -UseBasicParsing
            return $dest
        } catch {
            Add-Content -Path $LogFile -Value "$RepoUrl/$Name : $($_.Exception.Message)"
            return $null
        }
    }

    # ---------- fonts ----------
    $FontKey = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

    function Test-Font([string]$Name) {
        foreach ($key in 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts', $FontKey) {
            $item = Get-Item $key -ErrorAction SilentlyContinue
            if ($item -and ($item.GetValueNames() | Where-Object { $_ -like "$Name *" })) { return $true }
        }
        return $false
    }

    # Per-user install, so no admin rights are needed. AddFontResource makes the font
    # usable right away, without signing out.
    function Install-Font($Font) {
        if (-not ('Win32.FontMethods' -as [type])) {
            Add-Type -Namespace Win32 -Name FontMethods -MemberDefinition @'
[DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
public static extern int AddFontResourceW(string lpFileName);
'@
        }
        $dir = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
        if (-not (Test-Path $FontKey)) { New-Item -Path $FontKey | Out-Null }
        Write-Host "  Downloading $($Font.Name) ..." -ForegroundColor Cyan -NoNewline
        try {
            foreach ($file in $Font.Files) {
                $leaf = (Split-Path $file -Leaf) -replace '\[wght\]', ''
                $path = Join-Path $dir $leaf
                $url = "$FontUrl/" + ($file -replace '\[', '%5B' -replace '\]', '%5D')
                Add-Content -Path $LogFile -Value "`r`n> download $url"
                Invoke-WebRequest -Uri $url -OutFile "$path.part" -UseBasicParsing
                Move-Item -LiteralPath "$path.part" -Destination $path -Force
                $style = if ($leaf -like '*-Italic*') { ' Italic' } else { '' }
                Set-ItemProperty -Path $FontKey -Name "$($Font.Name)$style (TrueType)" -Value $path
                [void][Win32.FontMethods]::AddFontResourceW($path)
            }
            Write-Host "`r" -NoNewline
            Write-Ok "Installed $($Font.Name)"
            return $true
        } catch {
            Write-Host ''
            Add-Content -Path $LogFile -Value $_.Exception.Message
            Write-Bad "Could not install $($Font.Name)"
            return $false
        }
    }

    # ---------- VS Code ----------
    function Find-VSCode {
        $cmd = Get-Command 'code.cmd' -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($cmd) { return $cmd.Source }
        foreach ($path in "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd", "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd") {
            if (Test-Path $path) { return $path }
        }
        return $null
    }

    # ---------- main ----------
    try {
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
        if (-not (Invoke-Spin 'Upgrading pip' $python ($PipInstall + $pipUser + 'pip'))) {
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
        $packages = @(Read-Packages)
        $failed = @()
        if ($packages.Count -eq 0) {
            Write-Info 'No libraries selected'
        } else {
            for ($i = 0; $i -lt $packages.Count; $i++) {
                $pkg = $packages[$i]
                $label = "$(Get-Bar ($i + 1) $packages.Count)  $pkg"
                if (-not (Invoke-Spin $label $python ($PipInstall + $pipUser + $pkg))) {
                    $failed += $pkg
                }
            }
        }
        # numpy is what the course uses, so make sure it really loads.
        if (($packages -contains 'numpy') -and ($failed -notcontains 'numpy')) {
            if (-not (Invoke-Spin 'Checking that numpy works' $python @('-c', 'import numpy'))) { $failed += 'numpy' }
        }

        Write-Step 'Installing fonts'
        $fontsFailed = @()
        foreach ($font in $Fonts) {
            if (Test-Font $font.Name) { Write-Ok "Already installed: $($font.Name)" }
            elseif (-not (Install-Font $font)) { $fontsFailed += $font.Name }
        }

        # VS Code can't import a .code-profile from the command line, so apply_profile.py
        # puts the profile's settings and snippets into the default profile, and the
        # extensions it lists are installed one by one.
        Write-Step 'Setting up VS Code'
        $vscode = 'not found'
        $extFailed = @()
        $code = Find-VSCode
        if (-not $code) {
            Write-Warn 'VS Code not found. Install it from https://code.visualstudio.com and run this setup again.'
        } else {
            $helper = Get-RepoFile 'apply_profile.py'
            $profileFile = Get-RepoFile 'python-dev.code-profile'
            if (-not ($helper -and $profileFile)) {
                Write-Bad "Could not get the VS Code profile from $RepoUrl"
                $vscode = 'failed'
            } else {
                $userDir = Join-Path $env:APPDATA 'Code\User'
                $vscode = 'profile applied'
                if (-not (Invoke-Spin 'Applying settings, theme and snippets' $python @($helper, $profileFile, 'settings', $userDir))) {
                    $vscode = 'settings not applied'
                }
                $extensions = @(& $python $helper $profileFile extensions 2>$null | Where-Object { $_ })
                for ($i = 0; $i -lt $extensions.Count; $i++) {
                    $ext = $extensions[$i]
                    $label = "$(Get-Bar ($i + 1) $extensions.Count)  $ext"
                    if (-not (Invoke-Spin $label $code @('--install-extension', $ext))) { $extFailed += $ext }
                }
            }
        }

        # ---------- summary ----------
        Write-Host ''
        Write-Host '  +------------------------------------------+' -ForegroundColor Green
        Write-Host '  |              Setup complete              |' -ForegroundColor Green
        Write-Host '  +------------------------------------------+' -ForegroundColor Green
        Write-Host "  Python       $(& $python --version 2>&1)"
        Write-Host "  Location     $python"
        Write-Host "  Libraries    $($packages.Count - $failed.Count) installed"
        Write-Host "  Fonts        $($Fonts.Count - $fontsFailed.Count) of $($Fonts.Count) ready"
        Write-Host "  VS Code      $vscode"
        $failed += $fontsFailed + $extFailed
        if ($failed.Count -gt 0) {
            Write-Host '  Failed       ' -ForegroundColor Red -NoNewline
            Write-Host ($failed -join ' ')
            Write-Info "Details in $LogFile"
        }
        Write-Host ''
        Write-Host '  Next: ' -ForegroundColor White -NoNewline
        Write-Host 'open a new terminal, then try'
        Write-Host '    python -c "import sys; print(sys.executable)"' -ForegroundColor Cyan
        if ($vscode -eq 'profile applied') { Write-Info 'Restart VS Code to see the new theme and fonts.' }
        Write-Host ''
    } catch {
        if ("$_" -ne $Stopped) {
            Write-Bad "$_"
            Write-Host "  See the log: $LogFile" -ForegroundColor DarkGray
            Write-Host ''
        }
        # A script run from a file reports the failure to its caller. A piped run must
        # not call exit, because that would close the user's PowerShell window.
        if ($PSCommandPath) { exit 1 }
    }
}
