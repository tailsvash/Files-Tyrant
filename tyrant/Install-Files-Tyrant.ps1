# Installs Files Tyrant on this PC (Windows 10/11, 64-bit).
# Run by double-clicking Install-Files-Tyrant.cmd (it asks for admin once).

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
    exit
}

try {
    $cer = Join-Path $here 'FilesTyrant.cer'
    $bundle = Get-ChildItem $here -Filter *.msixbundle -Recurse | Where-Object { $_.DirectoryName -notmatch 'Dependencies' } | Select-Object -First 1
    if (-not $bundle) { throw 'Could not find the Files Tyrant package next to this script. Did you unzip everything first?' }

    Write-Host 'Step 1/2: trusting the Files Tyrant signing certificate (this is what lets Windows install it)...'
    Import-Certificate -FilePath $cer -CertStoreLocation Cert:\LocalMachine\TrustedPeople | Out-Null

    Write-Host 'Step 2/2: installing Files Tyrant...'
    $deps = @(Get-ChildItem $here -Filter *.appx -Recurse | Where-Object { $_.DirectoryName -match 'x64' -or $_.DirectoryName -notmatch 'arm|x86' } | Select-Object -ExpandProperty FullName)
    if ($deps.Count -gt 0) {
        Add-AppxPackage -Path $bundle.FullName -DependencyPath $deps -ForceUpdateFromAnyVersion
    } else {
        Add-AppxPackage -Path $bundle.FullName -ForceUpdateFromAnyVersion
    }

    Write-Host ''
    Write-Host 'Done! Search for "Files Tyrant" in the Start menu.' -ForegroundColor Green
}
catch {
    Write-Host ''
    Write-Host "Install failed: $($_.Exception.Message)" -ForegroundColor Red
}
Read-Host 'Press Enter to close'
