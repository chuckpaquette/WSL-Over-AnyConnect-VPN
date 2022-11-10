# WSL-Over-AnyConnect-VPN
My own PowerShell script to change the ifMetric in Windows to allow WSL connectivity while on the Cisco AnyConnect VPN.

What this Script is Solving For:
The Linux distribution installed within WSL cannot connect to my company's network (or anything else) when using Cisco AnyConnect VPN. This script will change the Windows routing allowing connectivity over the Cisco AnyConnect VPN. This script will also output the suggested VPN DNS entries to utilize in the WSL Linux instances.

Why is this Happening:
Windows uses the concept of interface metric (ifMetric) when deciding which interface to send IP traffic. The lowest metric is chosen (think of this as cost). Usually, the fastest interface would be the one with the lowest ifMetric giving it the priority. Also, from the output of:
** PS C:\> Get-NetIPConfiguration | Format-Table -Property InterfaceIndex,InterfaceAlias,InterfaceDescription,IPv4Address **
we can see that the current version of WSL uses a Hyper-V IP adapter. Presumably the WSL IP adapter is a NATed.

After connecting to the VPN, the Cisco AnyConnect adapter has added some routes and duplicated all the other routes:
** PS C:\> Get-NetRoute -AddressFamily IPv4 -InterfaceIndex <Enter-VPN-Adapter-Index-Here> | Format-Table** 
This is where the ifMetric column becomes important as my company's administrators have given the Cisco AnyConnect adapter the priority (lowest metric). The problem with this common practice is that the WSL adapter will now chose the Cisco AnyConnect adapter to send traffic instead of the Hyper-V IP adapter.

The Simple Routing Fix:
We'll give the Cisco AnyConnect adapter a higher ifMetric than the Hyper-V adapter. This will allow the WSL IP traffic to flow through the Hyper-V interface, apply NAT, then continue routing through the Cisco AnyConnect adapter.
