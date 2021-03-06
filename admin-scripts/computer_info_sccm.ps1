<#
----------------------------------------------------
Title: Computer Info From SCCm
Author: Michael Mayer
Description: Retrieves information about a computer from SCCM
Created: 01-18-2012
----------------------------------------------------
#>
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}

do{
$computername = read-host "Computer Name" #asks user for computer name
$sccm_info = get-wmiobject -query "select * from SMS_R_System where Name = '$computername'" -ComputerName ucrxsn01 -Namespace "root/sms/site_ucx" #runs sql query to get info from ucrxsn01
get-wmiobject -query "select * from SMS_R_System where Name = '$computername'" -ComputerName ucrxsn01 -Namespace "root/sms/site_ucx" > $computername".txt" #outputs sql query to textfile
$sccm_info #writes the sccm_info variable to the screen
} while ($sccm_info -eq $null)

$sccmtxt = Get-ChildItem $computername".txt"
email-report "SCCM report for $computername" "See attached" $sccmtxt 
    
remove-item $computername".txt" -force #deletes temp file for email