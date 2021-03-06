<#
----------------------------------------------------
Title: Mailbox Size
Author: Michael Mayer
Description: This code is designed to get the mailbox size of a specific mailbox
Created: 12-15-2011
----------------------------------------------------
#>
#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}


Write-Host "Establishing Connection ucrx-ex-03"
$session = new-pssession -configurationName Microsoft.Exchange -ConnectionUri http://ucrx-ex-03/Powershell/ -Authentication Kerberos #establishes connection to the exchange server using current users credentials
Import-PSSession $session -allowClobber | Out-Null #imports remote powershell cmdlets to local powershell. Allowclobber suppresses an error if the cmdlets for exchange have already been imported
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

$user = user-select "Mailbox"
$mbstats = get-mailboxstatistics -identity $user.samaccountname #gets mailbox info

# Get the mailbox, break if it's not found
$mb = Get-Mailbox $user.samaccountname -ErrorAction Stop

If ($mb.UseDatabaseQuotaDefaults -eq $true) {
      $quota = (Get-MailboxDatabase -Identity $mb.Database).ProhibitSendQuota
} else {
      $quota = $mb.ProhibitSendQuota
}
 
# Get the mailbox size and convert it from bytes to megabytes
$size = $mbstats.TotalItemSize

# Write the output
Write-Host "Mailbox:   " $mb.DisplayName
Write-Host "Size (MB): " $size
Write-Host "Quota (MB):" $quota
#Write-Host "Percent:   " ($size/$quota*100)

#writes mailbox info to text file
Add-Content mailboxsize.txt "Mailbox:$($mb.DisplayName)" 
Add-Content mailboxsize.txt "Size (MB):$size"
Add-Content mailboxsize.txt "Quota (MB):$quota"

$path = Get-ChildItem "mailboxsize.txt"
Email-Report "$($mb.DisplayName) Mailbox Size Report" "See attached" $path

Remove-PSSession $Session #disconnects from ucrx-ex-03
remove-item mailboxsize.txt -force