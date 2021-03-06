<#
----------------------------------------------------
Title: Add user to Group (DG or SG)
Author: Michael Mayer
Description: Used to add a single user to a DG or SG
Created: 01-24-2012
----------------------------------------------------
#>

import-module ActiveDirectory

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}

$user = user-select "Username" #calls function to get username
$primary_group = group-select "Group Name" #calls function to select group name
$groupname = $primary_group.name

Add-AdGroupMember -Identity $groupname -Member $user.SamAccountName

get-adgroupmember $primary_group | Sort-Object SamAccountName |format-table -Auto Name, SamAccountName, objectclass #outputs a nicely formatted table of group membes
(get-adgroupmember $primary_group | Sort-Object SamAccountName | format-table -Auto Name, SamAccountName, objectclass) > $groupname".txt" #outputs report to textfile

$path = Get-ChildItem $groupname".txt"
Email-Report "Group Membership Report" "See attached" $path
remove-item $groupname".txt" -force