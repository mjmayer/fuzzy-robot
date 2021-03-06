<#
----------------------------------------------------
Title: Grant "Send on Behalf" for Email Account
Author: Michael Mayer
Description: Asks for username and email account to grant send on behalf of permisssions
Created: 12-20-2011
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

$gen_mailbox = user-select "Generic Mailbox"
$user_array = @() #initializes array for storing numerous users

do{
$user = user-select "User to Grant Send-On-Behalf Permissions"
$user_array = $user_array + $user.samaccountname #adds selected user to array
$another_user = read-host "Grant Permission to another user"
}while ($another_user -ne "n")

get-mailbox $gen_mailbox.samaccountname | foreach {
   $a=@() 
   #enumerate existing values
   foreach ($granted in $_.GrantSendOnBehalfTo) {
     $a+=$granted
   }
   #add the new user 
   for ($i = 0; $i -lt $user_array.count;$i++) 
    {
        $a+= $user_array[$i]
    }
   set-mailbox $gen_mailbox.samaccountname -grantSendonBehalfTo $a #grants sendas permissions to users in $a array
 }
get-mailbox $gen_mailbox.samaccountname | select-object grantsendonbehalfto
Remove-PSSession $Session #disconnects from ucrx-ex-03
