<#
----------------------------------------------------
Title: Add Computer to Group
Author: Michael Mayer
Description: Used to add a single computer a Security Group
Created: 11-08-2013
----------------------------------------------------
#>

import-module ActiveDirectory

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}

$compName = computer_select "Computer Name"
$groupName = group-select "Group Name"


#confirmation from user
do{
    Write-host "Confirm addition of $($compName.Name) to $($groupName.Name)"
    $verify = read-host "Enter Confirmation (Y/N)"
    if ($verify -eq "N"){exit} #exit if n is pressed
} while ("y" -ne $verify) #keeps in loop until c is pressed or confirmed

#adds computer to the security group
Add-ADGroupMember -identity $groupName.Name -Members "$($compName.DistinguishedName)"


$AddConfirm = Get-ADGroupMember -Identity $groupName.Name | Select-String -Pattern "$compName" #parses group membership looking for the computer that was just added.
if($AddConfirm -ne $null){
    Write-Host "$($compName.Name) is a member of $($groupname.Name)"
    }