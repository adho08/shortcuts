param(
    [Parameter(Mandatory=$true)]
    [int]$hwnd
)

# Create the function to get ApplicationUserModelId
$code = @"
using System;
using System.Runtime.InteropServices;

public class GetAumid {
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);

    [DllImport("kernel32.dll")]
    public static extern IntPtr OpenProcess(uint dwDesiredAccess, bool bInheritHandle, uint dwProcessId);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool CloseHandle(IntPtr hHandle);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool QueryFullProcessImageName(IntPtr hProcess, uint dwFlags, System.Text.StringBuilder lpExeName, ref uint lpdwSize);

    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern int GetPackageFullName(IntPtr hProcess, ref uint packageFullNameLength, System.Text.StringBuilder packageFullName);
}
"@

Add-Type -TypeDefinition $code

$processId = 0
[GetAumid]::GetWindowThreadProcessId([IntPtr]$hwnd, [ref]$processId)

$PROCESS_QUERY_LIMITED_INFORMATION = 0x1000
$hProcess = [GetAumid]::OpenProcess($PROCESS_QUERY_LIMITED_INFORMATION, $false, $processId)

$nameBuilder = New-Object System.Text.StringBuilder 1024
$nameLength = 1024
$packageNameBuilder = New-Object System.Text.StringBuilder 1024
$packageNameLength = 1024

$result = [GetAumid]::GetPackageFullName($hProcess, [ref]$packageNameLength, $packageNameBuilder)

if ($result -eq 0) {
    $packageName = $packageNameBuilder.ToString()
    Write-Host "Package Full Name: $packageName"
    
    # Get AUMID using Get-AppxPackage
    $aumid = (Get-AppxPackage | Where-Object { $_.PackageFullName -eq $packageName }).PackageFamilyName
    Write-Host "AUMID: $aumid"
} else {
    Write-Host "Not a UWP app or error getting package name. Error code: $result"
}

[GetAumid]::CloseHandle($hProcess)