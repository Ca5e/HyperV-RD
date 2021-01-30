#
# adds all entries of OU to a specific group.
#

Import-Module ServerManager

$StrOU="OU=RDS Servers,DC=domain,DC=tld"
$StrGroup="FSLogix Systems"

Add-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

# Searches in AD and adds resulting "principal" to Group
Get-ADComputer -Server DC01 -SearchBase "$StrOU" -Filter "*" | Add-ADPrincipalGroupMembership -MemberOf $StrGroup
