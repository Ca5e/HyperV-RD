#
# Renames a Windows machine's computername to the name given
# inside the Hyper-V envrioment
#

Import-Module ServerManager
Add-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature
Import-Module RemoteDesktop
Enable-PSRemoting -Force

# Uses Hyper-V VirtualMachine name as string
$StrComputer=(Get-item "HKLM:\SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters").GetValue("VirtualMachineName")

# Adds current computername to string
$StrCurrent="$env:computername"

# Tries to rename computer account to string
	Try 
	{
		Rename-Computer $StrComputer -ErrorAction Stop
	}
# Catches error if name is the same as current name and displays error
	catch [System.InvalidOperationException]
	{
		Write-Host $_.Exception.Message
	# If Exception message is eq to "" then...
		if ($_.Exception.Message -eq "Skip computer '$StrComputer' with new name '$StrComputer' because the new name is the same as the current name.")
		{
		Write-Host "Nothing to do, computername is already correct. Ending script."
		}
		ElseIf ($_.Exception.Message -eq "Fail to rename computer '$StrCurrent' to '$StrComputer' due to the following exception: The account already exists.")
		{
		Write-Host "Computername is already in use, removing computername from AD and retrying."
		Get-ADComputer $StrComputer | Remove-ADObject -Recursive -Confirm:$false
		Rename-Computer $StrComputer
		}
		Else
		{
		Write-Host "Don't know what to do with error. Run, panic."
		}
	}
	catch
	{
		Write-Host $_.Exception.Message
		Write-Host "Not sure what to do now..."
	}
