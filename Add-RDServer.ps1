#
# Executes commands on the Connection Broker from a newly
# added VM to add it to the remote desktop environment.
#

Import-Module RemoteDesktop
Enable-PSRemoting -Force

# Uses current computername as $StrRd.
$StrRD="$env:computername.domain.tld"
$StrCB="CB01.domain.tld"
$StrGW="GW01.domain.tld"
$StrCollection="Collection name"

# Executes script to add clients to CB server manager

Invoke-Command -ComputerName $StrCB -ScriptBlock {
	"$env:computername.domain.tld" -f $using:StrRD
	
	get-process ServerManager | stop-process –force
	$file = get-item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\ServerManager\ServerList.xml"
	copy-item –path $file –destination $file-backup –force
	$xml = [xml] (get-content $file )
	$newserver = @($xml.ServerList.ServerInfo)[0].clone()
	$newserver.name = $using:StrRD 
	$newserver.lastUpdateTime = “0001-01-01T00:00:00” 
	$newserver.status = “2”
	$xml.ServerList.AppendChild($newserver)
	$xml.Save($file.FullName)
	start-process –filepath $env:SystemRoot\System32\ServerManager.exe –WindowStyle Maximized
}

# Adds RD to CB.
New-RDSessionDeployment -ConnectionBroker $StrCB -WebAccessServer $StrGW -SessionHost $StrRD
Add-RDServer -Server $StrRD -Role RDS-RD-SERVER -ConnectionBroker $StrCB
Add-RDSessionHost -SessionHost $StrRD -ConnectionBroker $StrCB -CollectionName $StrCollection
Add-RDVirtualDesktopToCollection -ConnectionBroker $StrCB -CollectionName $StrCollection -VirtualDesktopName $StrRD
# Makes sure new connections are allowed
Set-RDSessionHost -SessionHost $StrRD -NewConnectionAllowed Yes -ConnectionBroker $StrCB
