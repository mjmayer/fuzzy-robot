<#
----------------------------------------------------
Title: Group Membership Report
Author: Michael Mayer
Description: Shows Members of Groups
Created: 11-30-2011
----------------------------------------------------
#>
$error.clear() #clears error log
$erroractionpreference = "SilentlyContinue"
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}


$primary_group = group-select "Group Name" #calls function to select group name
$groupname = $primary_group.name
get-adgroupmember $primary_group | Sort-Object SamAccountName |format-table -Auto Name, SamAccountName, objectclass #outputs a nicely formatted table of group membes

if (!$?) #if no group is selected the script errors out. This loop posts the error and exits.
    {
        "An exception has occurred. No valid user group was selected" #posts error and exits
        exit
    }
(get-adgroupmember $primary_group | Sort-Object SamAccountName | format-table -Auto Name, SamAccountName, objectclass) > $groupname".txt" #outputs report to textfile

$path = Get-ChildItem $groupname".txt"
Email-Report "Group Membership Report" "See attached" $path
remove-item $groupname".txt" -force