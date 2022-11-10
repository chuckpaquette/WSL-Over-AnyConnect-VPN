<#
.SYNOPSIS
This script will set the ifMetric cost of a VPN adapter

.DESCRIPTION
This script was written to solve the problem where WSL instances would not connect over an active VPN. WSL uses a HyperV interface along with NAT to connect to the outside world. However, the WSL/HyperV routing breaks when a VPN is in use. This script will set the ifMetric cost of the VPN adapter to a high value allowing the WSL/HyperV traffic to run through NAT. The output of this script also includes suggested DNS entries to utilize within your WSL instances. Use the -showRoute switch to see the routing tables before and after this script makes the changes.

This script must be run with Administrator privileges

.LINK
See: https://github.com/chuckpaquette/WSL-Over-AnyConnect-VPN
#>

Param(
    [Parameter(Mandatory=$false)]
    [switch]$showRoute
)
# $ifCost sets the ifMetric on the VPN specified by $adapter
$ifCost = 6000
$adapter = "Cisco AnyConnect"
function getRoute {
    Get-NetAdapter |
        Where-Object {$_.InterfaceDescription -Match $adapter} |
            Get-NetRoute -AddressFamily IPv4
    }

# Check to see if this PS running as administrator
Write-Host "Checking for Administrator permissions..."
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Insufficient permissions to run this script. Open the PowerShell console as an administrator and run this script again."
    Break
}
Write-Host "Code is running as administrator - Executing the WSL on VPN script..." -ForegroundColor Green

if ($showRoute){
Write-Host "`n$adapter Routing table before making the changes:"
getRoute
}

# Check to see if Cisco AnyConnect VPN is active
# VPN Check was derived from: # https://www.harrycaskey.com/detect-vpn-connection-with-powershell/
Write-Host "Checking to see if AnyConnect VPN is active..."
$vpnCheck = Get-WmiObject -Query "Select Name,NetEnabled from Win32_NetworkAdapter where (Name like '%$adapter%') and NetEnabled='True'"
$vpnCheck = [bool]$vpnCheck
if (!$vpnCheck){
    Write-Warning "A VPN is not active for $adapter.`nPlease connect your VPN and run this script again."
    Break
}
else {
    Write-Host "$adapter VPN is Active." -ForegroundColor Green
}
# Change the ifMetric Priority
Write-Host "Changing $adapter ifMetric to ${ifCost}..."
Get-NetAdapter |
    Where-Object {$_.InterfaceDescription -Match $adapter} |
        Set-NetIPInterface -InterfaceMetric $ifCost

# Let user know that ifMetric has changed
if ($showRoute){
    Write-Host "`n$adapter Routing after making the changes:"
    getRoute
}

# Getting the DNS addresses from Windows to import into WSL
Write-Host "Obtaining DNS addresses..."
Write-Host "`nCopy and Paste the Following into your WSL /etc/resolve.conf file:`n"
$dnsAddresses = (Get-NetAdapter | Where-Object InterfaceDescription -like $adapter* | Get-DnsClientServerAddress).ServerAddresses
$dnsAddresses | ForEach-Object {
    Write-Host "nameserver $_"
}