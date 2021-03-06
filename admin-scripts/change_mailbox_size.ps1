<#
----------------------------------------------------
Title: Change Mailbox Size
Author: Michael Mayer
Description: Reports Mailbox size and can change mailbox size
Created: 01-25-2012
----------------------------------------------------
#>
Write-Host "Establishing Connection ucrx-ex-03"
$session = new-pssession -configurationName Microsoft.Exchange -ConnectionUri http://ucrx-ex-03/Powershell/ -Authentication Kerberos #establishes connection to the exchange server using current users credentials
Import-PSSession $session -allowClobber | Out-Null #imports remote powershell cmdlets to local powershell. Allowclobber suppresses an error if the cmdlets for exchange have already been imported
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}


#gets information about the mailbox. Writes to a text file. Takes the mailbox name as a parameter
function mailbox-report
{
PARAM
(
    [Parameter(Mandatory=$false)]
    $user
)

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

return $null
}

#asks for username and verifies user has a mailbox
$user1 = user-select "Mailbox"
$mb = Get-Mailbox $user1.samaccountname -ErrorAction Stop

#writes a header to the mailboxsize.txt file and runs the report which writes mailbox name, mailbox size, and quota to a file & console
Add-Content mailboxsize.txt "INITIAL MAILBOX SIZE"
mailbox-report $user1

#asks user which mailbox size to use
$role = item-select "Staff", "Student", "Custom"

#sets mailbox size to the default for the database
if($role -eq "staff"){set-mailbox -identity $($mb.DisplayName) -UseDatabaseQuotaDefaults $true | Out-Null}

#sets mailbox size to 150,175,200MB
if($role -eq "student"){set-mailbox -identity $($mb.DisplayName) -Database "Mailbox Database 1623792863" -IssueWarningQuota 157286400 -ProhibitSendQuota 183500800 -ProhibitSendReceiveQuota 209715200 -UseDatabaseQuotaDefaults $false | Out-Null}

#Allows for user to put in a different sized mailbox. Since exchange expects it in KB the MB need to be converted.
if($role -eq "Custom"){
    do{
        [int]$mbsize = read-host "Mailbox size (MB)" #asks for size of mailbox
        } while (!($mbsize -match "^\d"))
    [int]$b = $mbsize*1048576
    [int]$b25 = $b+(25*1048576)
    [int]$b50 = $b25+(25*1048576)
    set-mailbox -identity $($mb.DisplayName) -Database "Mailbox Database 1623792863" -IssueWarningQuota $b -ProhibitSendQuota $b25 -ProhibitSendReceiveQuota $b50 -UseDatabaseQuotaDefaults $false | Out-Null
}

#adds a new line to mailboxsize.txt then runs the mailbox size report again to verify the change.
Add-Content mailboxsize.txt "NEW MAILBOX SIZE"
mailbox-report $user1

#emails report        
$path = Get-ChildItem "mailboxsize.txt"
Email-Report "$($mb.DisplayName) Mailbox Size Report" "See attached" $path

Remove-PSSession $Session #disconnects from ucrx-ex-03
remove-item mailboxsize.txt -force