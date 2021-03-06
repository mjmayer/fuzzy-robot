<#
----------------------------------------------------
Title: Admin Report for Password Expiration
Author: Michael Mayer
Description: Finds out which users have passwords expiring soon
Created: 11-21-2011
----------------------------------------------------
#>
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

#imports modules depending on directory
$path1 = get-location
if($path1.path -match "admin-scripts"){Import-Module ..\modules\mmodules.psm1 -force}
else{Import-Module .\modules\mmodules.psm1 -force}

do{
$report_type = read-host "(I)ndividual or (G)roup Report" #ask if it is an indivudal or group report
} while (!($report_type -match "^[ig]"))

if($report_type -eq "g"){ 
    $usersPWage = get-aduser -filter 'enabled -eq $true' -properties PasswordLastSet,PasswordNeverExpires,EmailAddress,Name,CannotChangePassword #filters AD for enabled accounts and retrieves relevant properites
    do{
        $days = read-host "Number of Days to Search for Users with Expiring Password (default 30)" #asks for number of days to display expiring passwords
    if ($days -eq ""){$days = 30} #sets days to 30 if no input is received
    } while (!($days -match "^\d")) #keeps
}

if($report_type -eq "i"){
    $user= user-select "Username"
    [array]$userspwage = get-aduser -identity $user.samaccountname -properties PasswordLastSet,PasswordNeverExpires,EmailAddress,Name,CannotChangePassword
    [int]$days = 1000
}
    
$pwPolicy = get-addefaultdomainpasswordpolicy #retrives domain's password policy
[double]$pwMaxAge =  $pwPolicy.MaxPasswordAge.Days #sets $pwMaxAge to the number of days in the domains password policy

$date = get-date #gets date for comparisons
$expire_report = @() #initializes array for users who have passwords expiring today.



for ($i=0; $i -lt $userspwage.count; $i++){ #loop to move through all users filtered from Ad
 if (($usersPWage[$i].PasswordLastSet) -and ($usersPWage[$i].EmailAddress) -and ($usersPWage[$i].CannotChangePassword -eq $false)){ #this loop on runs if the user has an email address, can change their password
    $Expiredate=$usersPWage[$i].PasswordLastSet +  $pwPolicy.MaxPasswordAge
    $PasswordAgeLeft=$ExpireDate-$date
    $Daysleft=$PasswordAgeleft.days
    }
 if(($usersPWage[$i].PasswordNeverExpires -ne $true) -and ($DaysLeft -ge 0) -and ($DaysLeft -le $days)){ #loop to send
    #emails to the users. Only send on days 20,14,7,5,2,1,0
    $outputphrase = $null
    switch ($DaysLeft) { #sets phrase for email.
        0 {$outputphrase = “will expire today“ ; break}
        1 {$outputphrase = “will expire in 1 day“ ; break}
        Default {$outputphrase = “will expire in $DaysLeft days“}
        }
        #write-host "$($usersPWage[$i].SamAccountName) password $outputphrase"
        $message = "$($usersPWage[$i].SamAccountName) password $outputphrase"
        $expire_report += ,@($DaysLeft,$message) #puts $daysleft and $message into a multidemnsional array for later sorting
}
}


$expire_report_byage = $expire_report | sort-object @{Expression={$_[0]}; Ascending=$true} #sorts the table according to password expiration
$email_report = @()

if($report_type -eq "g"){ #loops through array of users creating a string for emailing purposes,
    for ([int]$i=0; $i -lt $expire_report_byage.length; $i++){ #loop to display the array excluding the first column in the array
     write-host $expire_report_byage[$i][1]
     add-content "password_report.txt" "$($expire_report_byage[$i][1])`n"
    }
}

if($report_type -eq "i"){ #runs if only 1 person is selected for the report.
    write-host $expire_report_byage[1]
    "$($expire_report_byage[1])`n" > "password_report.txt" #outputs report to textfile
}


$path = Get-ChildItem "password_report.txt"
Email-Report "Password Expiration Report" "See attached" $path
remove-item "password_report.txt" -force