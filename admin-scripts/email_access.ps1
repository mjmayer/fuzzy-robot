<#
----------------------------------------------------
Title: Add Mailbox Permissions
Author: Michael Mayer
Description: Grants specified user full mailbox access and the option to "send-as"
Created: 11-30-2011
----------------------------------------------------
#>
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}

Write-Host "Establishing Connection ucrx-ex-03"
$session = new-pssession -configurationName Microsoft.Exchange -ConnectionUri http://ucrx-ex-03/Powershell/ -Authentication Kerberos #establishes connection to the exchange server using current users credentials
Import-PSSession $session -allowClobber | Out-Null #imports remote powershell cmdlets to local powershell. Allowclobber suppresses an error if the cmdlets for exchange have already been imported



<#
Summary:		Takes an array and displays the values in it for selection by the user.
Parameters:		array of values and the display property name
Return:			Value selected
#>

function Select-TextItem
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    $options,
    $displayProperty
)

    [int]$optionPrefix = 1
    # Create menu list
    foreach ($option in $options)
    {
        if ($displayProperty -eq $null)
        {
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option)
        }
        else
        {
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"To cancel") 
    [int]$response = Read-Host "Enter Selection"
    $val = $null
    if ($response -gt 0 -and $response -le $options.Count)
    {
        $val = $options[$response-1]
    }
    elseif ($response = 0)
    {
        exit
    }
    #return $val
    return $response
}

$mailbox = user-select "Mailbox to grant permissions on" #asks for for user from AD
$check_mail = get-mailbox -identity $mailbox.samaccountname #checks to see if there is an mailbox that matches the $user.samaccountname
if ($check_mail -eq $null){ #alternate serach for mailbox if the $user.samaccountname does not match mailbox name
    $check_mail = get-mailbox -identity $check_mail.emailaddress
}

if($check_mail -eq $null){ #if after both checks for a mailbox the script outputs that the selected user does not have a mailbox
    write-host "$user does not have a mailbox"
}

$user = user-select "User to grant permissions to" #gets user to give permissions to
$values = "Grant Full Access Permission", "Grant Send-As Permission", "Grant Full Access Permission and Send-As Permission" #values for list
$per_select = Select-TextItem $values "Displayname" #asks user to select value from $values

switch ($per_select){
    1{Add-MailboxPermission -Identity $($check_mail.alias) -User $($user.samaccountname) -AccessRights FullAccess #grants fullaccess permission to $checkmail address
      #get-mailboxpermission -Identity $($check_mail.alias) -User $($user.samaccountname) #outputs permission for user just added
      }
    2{Add-ADPermission -Identity $($mailbox.distinguishedname) -User $($user.samaccountname) -ExtendedRights Send-As #adds send as permison to $mailbox
      write-host "If Deny is False, the listed user has send as permssion"
      #get-adpermission -identity $check_mail.distinguishedname | where-object {($_.extendedrights -like "*send*") -and ($_.user -like "*$($user.samaccountname)*")}} #gets send as permissions
      }    
    3{Add-MailboxPermission -Identity $($check_mail.alias) -User $($user.samaccountname) -AccessRights FullAccess #adds full access permission
      Add-ADPermission -Identity $($mailbox.distinguishedname) -User $($user.samaccountname) -ExtendedRights Send-As  | out-null #adds send as permission
      #get-mailboxpermission -Identity $($check_mail.alias) -User $($user.samaccountname) #returns access rights for user on mailbox
      write-host "If Deny is False, the listed user has send as permssion"
      #get-adpermission -identity $check_mail.distinguishedname | where-object {($_.extendedrights -like "*send*") -and ($_.user -like "*$($user.samaccountname)*")}} #gets send as permissions
      }
}

Remove-PSSession $Session | out-null #disconnects from ucrx-ex-03