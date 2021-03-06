<#
----------------------------------------------------
Title: Auto-Password reset
Author: Michael Mayer
Description: This code is designed reset users password
Created: 10-18-2011
----------------------------------------------------
#>
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD
#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}

<#
Summary:		Generates password
Parameters:		string that defines the prefix on the password
Return:			Returns password
#>
function pass([string]$a) #this function generates a password using a string provided followed by 4 random numbers
    {
        $rand = New-Object system.random
        $b = New-Object system.random
        $password = $a+=$rand.next(1000,9999)
        #write-host "Password:$password"
        return $password
    }   
    
$user = user-select "Username" #calls user_select function
$pass = pass("Unex_") #generates password for user
$secure = convertto-securestring $pass -asplaintext -force
$uObj = [ADSI]"LDAP://$user"
do{
    $change = read-host "User must change password at next login (Y/N)" #asks if user needs to change password on next login
   } while (($change -ne "y") -and ($change -ne "n")) #keeps in loop until valid input of y or n is received
Set-ADAccountPassword -Identity $user -Reset -NewPassword $secure #resets password
if($change -eq "y"){
    write-host "Waiting for Domain Controllers to Replicate"
    start-sleep -seconds 5
    $uObj.put("pwdLastSet",0) #sets pwdlastset to 0. This forces user to change password at next login
    $uObj.SetInfo()
    }
write-host "Password for $($user.samaccountname) has been changed to $pass"
