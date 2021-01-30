#
# Handles automatic configuration of VM's in $OUpath by 
# changing boot order to execute a network boot.
#

Import-Module ServerManager
Import-Module RemoteDesktop
Add-WindowsFeature -Name "RSAT-AD-PowerShell" -IncludeAllSubFeature

$OUpath="OU=RDS Servers,DC=domain,DC=tld"
$ExportPath="\\10.0.0.2\Documents\RD-client.txt"
$CB="CB01.domain.tld"
$WaitTime=300
# Regex only selects items starting with RD
$regex='^"RD'

Get-ADComputer -Server DC01 -SearchBase "$OUpath" -Filter "*" | Select-object DNSHostName | Export-Csv -NoType $ExportPath

# Select all computers in the OUpath and starts a For-Each loop based on the object name
$RDS=Get-ADComputer -Server domain.tld -SearchBase "$OUpath" -Filter "*" | Select-object Name
foreach($line in Get-Content \\10.0.0.2\Documents\RD-client.txt) {
    if($line -match $regex){
        # Removes quotation marks from string
        $DNSHostName=$line -replace '"', ""
        # Removes .domain.tld from name
        $VMName=$DNSHostName -replace '.domain.tld', ""
        $Firmware=Get-VMFirmware $VMName
            # To rearrange the bootorder, current bootdevices need to be stored in variables.
            $File=$Firmware.BootOrder[0]
            $Network=$Firmware.BootOrder[1]
            $Drive=$Firmware.BootOrder[2]
                
                # New connections not allowed on RD.
                Set-RDSessionHost -SessionHost $DNSHostName -NewConnectionAllowed no -ConnectionBroker $CB

                # Sends message to all logged-in users.
                Invoke-Command -ComputerName $VMName {msg * "Sla al uw werk op. U wordt over 5 minuten afgemeld."}

                Write-Host "Reconfig script will now be executed on $VMName"
            
                # Variables are changed to allow Network boot on VM X.
                Set-VMFirmware -VMName $VMName -BootOrder $Network,$File,$Drive
                
                # Timeout 1 can be skipped.
                $prompt = new-object -comobject wscript.shell 
                $answer = $prompt.popup("Skip user exit timeout?`n",$WaitTime,"title",6)              
                if($answer -eq 11) {Write-Host "Timeout was skipped using popup."}
                if($answer -eq 20) {Start-Sleep -Seconds $WaitTime}
                if($answer -eq -1) {Write-Host "$WaitTime elapsed, continuing."}
                if($answer -eq 2) {Exit}

                # Restart VM
                Stop-VM -Name $VMName
                Start-Sleep -Seconds 5
                Start-VM -Name $VMName


                # Prompts if timeout 2 (before next loop/VM) can be skipped.
                $prompt = new-object -comobject wscript.shell 
                $answer = $prompt.popup("Skip timeout and continue to next VM?`n",$WaitTime,"title",6)              
                if($answer -eq 11) {Write-Host "Timeout was skipped using popup."}
                if($answer -eq 10) {Start-Sleep -Seconds $WaitTime}
                if($answer -eq -1) {Write-Host "$WaitTime elapsed, continuing."}
                if($answer -eq 2) {Exit}
    }
}
