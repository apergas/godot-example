# Runs every tests/test_*.gd headless and exits with 1 if any of them fails.
# Usage: powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1 [-TimeoutSec 120] [-SkipImport]
param([int]$TimeoutSec = 120, [switch]$SkipImport)

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$logDir = Join-Path ([System.IO.Path]::GetTempPath()) "godot-example-tests"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

function Invoke-Godot {
	param([string]$GodotArgs, [string]$Name)
	$out = Join-Path $logDir "$Name.out.txt"
	$err = Join-Path $logDir "$Name.err.txt"
	$startArgs = @{
		FilePath = $env:ComSpec
		ArgumentList = "/c tools\godot.cmd $GodotArgs"
		WorkingDirectory = $root
		NoNewWindow = $true
		PassThru = $true
		RedirectStandardOutput = $out
		RedirectStandardError = $err
	}
	$proc = Start-Process @startArgs
	$null = $proc.Handle
	$timedOut = -not $proc.WaitForExit($TimeoutSec * 1000)
	if ($timedOut) {
		& taskkill.exe /T /F /PID $proc.Id 2>$null | Out-Null
	}
	$proc.WaitForExit()
	$text = @(Get-Content -Path $out, $err -ErrorAction SilentlyContinue) -join "`n"
	return [pscustomobject]@{ Code = $proc.ExitCode; TimedOut = $timedOut; Text = $text }
}

if (-not $SkipImport) {
	Write-Host "Importing project (refreshes class_name cache and .uid files)..."
	$import = Invoke-Godot "--headless --path . --import" "_import"
	if ($import.TimedOut) {
		Write-Host "Import timed out after $TimeoutSec s" -ForegroundColor Red
		exit 1
	}
}

$tests = @(Get-ChildItem -Path (Join-Path $root "tests") -Filter "test_*.gd" | Sort-Object Name)
if ($tests.Count -eq 0) {
	Write-Host "No tests found in tests/" -ForegroundColor Yellow
	exit 0
}

$failed = @()
foreach ($test in $tests) {
	$name = $test.BaseName
	$result = Invoke-Godot "--headless --path . --script res://tests/$($test.Name)" $name
	$reasons = @()
	if ($result.TimedOut) { $reasons += "timeout" }
	if ($result.Code -ne 0) { $reasons += "exit code $($result.Code)" }
	if ($result.Text -match "(?m)^FAIL ") { $reasons += "FAIL lines" }
	if ($result.Text -match "SCRIPT ERROR|Parse Error") { $reasons += "script error" }
	if ($result.Text -notmatch "(?m)^PASS ") { $reasons += "no PASS lines" }
	if ($reasons.Count -eq 0) {
		$passes = ([regex]::Matches($result.Text, "(?m)^PASS ")).Count
		Write-Host ("[ OK ] {0} ({1} checks)" -f $name, $passes) -ForegroundColor Green
	} else {
		$failed += $name
		Write-Host ("[FAIL] {0}: {1}" -f $name, ($reasons -join ", ")) -ForegroundColor Red
		Write-Host $result.Text
	}
}

Write-Host ""
Write-Host ("{0} test files, {1} failed" -f $tests.Count, $failed.Count)
if ($failed.Count -gt 0) { exit 1 }
exit 0
