[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][Uri]$ProxyUrl,
    [string]$ExecutablePath
)
$ErrorActionPreference = 'Stop'

if (!$ProxyUrl.IsAbsoluteUri -or $ProxyUrl.Scheme -ne 'http' -or $ProxyUrl.UserInfo) {
    throw 'Provide a credential-free local HTTP proxy URL, such as http://127.0.0.1:8080.'
}
if ($ProxyUrl.Host -notin '127.0.0.1','localhost','[::1]','::1') {
    throw 'This example launcher accepts loopback proxy addresses only.'
}
if ($ProxyUrl.AbsolutePath -ne '/' -or $ProxyUrl.Query -or $ProxyUrl.Fragment) {
    throw 'A proxy endpoint must contain only the scheme, loopback host, and port.'
}

$client = if ($ProxyUrl.Host -in '[::1]','::1') {
    New-Object System.Net.Sockets.TcpClient([System.Net.Sockets.AddressFamily]::InterNetworkV6)
} else {
    New-Object System.Net.Sockets.TcpClient
}
try {
    if (!$client.ConnectAsync($ProxyUrl.DnsSafeHost, $ProxyUrl.Port).Wait(3000)) {
        throw 'The local listener did not respond. Start your proxy and check its HTTP/mixed port.'
    }
} finally { $client.Close() }
# A TCP listener check does not establish HTTP CONNECT or upstream reliability.

if (!$ExecutablePath) {
    $package = Get-AppxPackage -Name 'OpenAI.Codex' |
        Sort-Object Version -Descending | Select-Object -First 1
    if (!$package) { throw 'Codex package not found. Supply -ExecutablePath for your installation.' }
    $ExecutablePath = Join-Path $package.InstallLocation 'app\ChatGPT.exe'
}
if (!(Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
    throw 'Desktop executable not found. Check your installation or -ExecutablePath.'
}
$ExecutablePath = (Resolve-Path -LiteralPath $ExecutablePath).Path
$running = Get-Process -Name 'ChatGPT' -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $ExecutablePath }
if ($running) {
    throw 'Codex is already running. Quit it normally from the tray, then rerun this launcher.'
}

$proxyAddress = $ProxyUrl.GetLeftPart([UriPartial]::Authority)
$env:HTTP_PROXY = $proxyAddress
$env:HTTPS_PROXY = $proxyAddress
$env:ALL_PROXY = $proxyAddress
$env:NO_PROXY = 'localhost,127.0.0.1,::1'
# Preserve an existing, deliberately configured CA variable; never disable TLS verification.
Start-Process -FilePath $ExecutablePath -ArgumentList ('--proxy-server=' + $proxyAddress) -WindowStyle Normal
Write-Output 'Codex desktop launched with process-scoped proxy settings.'
