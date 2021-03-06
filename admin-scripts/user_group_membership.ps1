<#
----------------------------------------------------
Title: Group Membership Report for a User
Author: Michael Mayer
Description: Lists Group Membership for a user
Created: 11-23-2011
----------------------------------------------------
#>
import-module ActiveDirectory

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}


#asks for account name
$uname_result = user-select "Enter Username"
if($uname_result -eq $null){ #exits program if no user is selected
    Remove-PSSession $Session
    exit
    } 
    
$MemberOf = (get-aduser -identity $uname_result -Properties MemberOf | Select-Object Memberof).MemberOf #gets a list of group membership
$group_mem=@() #initializes @memberof array. This will store our users SGs and DGs in a standard format
for ($i = 0; $i -lt $MemberOf.count;$i++) #loops for each object in $memeberof
{
    $group_mem += get-adgroup -identity $MemberOf[$i] #gets the users DGs and SGs into a standard format
}
if ($group_mem -eq $null){write-host -ForegroundColor red "This user does not belong to any security groups."}

$sg = @() #initialize $sg array
$dg = @() #initialize $dg array
for ($i=0; $i -lt $group_mem.count;$i++){
    if($group_mem[$i].groupCategory -eq "Security"){ #looks for security groups
       $sg += "$($group_mem[$i].name)`n" #adds security groups to the $sg array
       }
    if($group_mem[$i].groupCategory -eq "Distribution"){ #looks for distribution gorups
        $dg += "$($group_mem[$i].name)`n" #add distribution groups to the $dg array
       }
}
$sg_rep ="Security Groups`n$sg"
$dg_rep ="Distribution Groups`n$dg"
write-host "$($sg_rep)`n$($dg_rep)"
$email_report = $null #sets variable to null
[string]$email_report += "$($uname_result.samaccountname)`n" + $sg_rep + "`n" + $dg_rep

email-report "User Group Membership Report $($uname_result.samaccountname)" $email_report
