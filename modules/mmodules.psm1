<#
----------------------------------------------------
Title: Michael's Modules
Author: Michael Mayer
Description: Collection of modules used in my scripts
Created: 12-23-2012
----------------------------------------------------
#>


#>
<#
Summary:		Searches AD for a user. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		no parameter
Return:			Returns the member from the $options array that was chosen.
#>
Function User-Select {
PARAM 
(
    [Parameter(Mandatory=$true)]
    [string]$descrip,
    [string]$uname
)
    if($uname -eq ""){
        do{
            $uname = read-host $descrip #asks for string. $descrip is a parameter could be user name, requestor, etc
            $uname_star=$uname+="*" #adds a * to the $uname variable to facilitate the "Name - like $uname_star" search
            [array]$options = Get-ADUser -Filter {((SamAccountName -like $uname) -or (GivenName -like $uname) -or (Surname -like $uname) -or (Name -like $uname_star)) -and (Enabled -eq "True")}`
		    #searches AD for the username, givenname, surname, or login
            if($options -eq $null){write-host "I think you know what the problem is just as well as I do"} #outputs witty comment when user can't be found
        }while($options -eq $null)
    }
        
    if($uname -ne ""){
            $count = 0 #counter
            do{
                if($count -gt 0){$uname = read-host $descrip} #asks for string. $descrip is a parameter could be user name, requestor, etc
                $uname_star=$uname+="*" #adds a * to the $uname variable to facilitate the "Name - like $uname_star" search
                [array]$options = Get-ADUser -Filter {((SamAccountName -like $uname) -or (GivenName -like $uname) -or (Surname -like $uname) -or (Name -like $uname_star)) -and (Enabled -eq "True")}`
				#searches AD for the username, givenname, surname, or login
                if($options -eq $null){write-host "I think you know what the problem is just as well as I do"} #outputs witty comment when user can't be found
                $count++
    }while($options -eq $null)
    }
    $displayProperty = "Name"
    $displayProperty2 = "SamAccountName"
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
            Write-Host ("{0,3}: {1} ({2})" -f $optionPrefix,$option.$displayProperty,$option.$displayProperty2)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"Exit") 

    #verifies that the user input is in a valid format
    do{
    [int]$response = Read-Host "Enter Selection"
    } while (!($response -match "^\d") -or ($response -gt $options.count))
    
    $val = $null
    if ($response -gt 0 -and $response -le $options.Count)
    {
        $val = $options[$response-1]
    }
    elseif ($response = 0)
    {
        exit
    }
    return $val
}  



<#
Summary:		Searches AD for a user. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		$subject (subject of the email), $bodyvar (body of the email), $attachment (Get-ChildItem "c:\temp\temp.txt")
Return:			nothing
#>
Function Email-Report {
PARAM 
(
    [Parameter(Mandatory=$true)]
    [string]$subject,
    [string]$bodyvar,
    [Parameter(Mandatory=$false)]
    $attachment
)

   $user1 = read-host "Username for Email Report (leave blank for no email)" #asks for username for email
   if($user1 -eq ""){exit} #exit function if no username is entered for email report

    #asks user for a username to email the report. If no username is provided skips user_select function.
    if($user1 -ne ""){
        $emailuser = user-select "Username" $user1 #calls the userlookup function putting using the $user1 variable for the search
    }

    #asks for CC on email
    if($emailuser -ne ""){
        $user2 = read-host "Username for CC on Email Report (leave blank for no CC)"
    }

    if($user2 -ne ""){
        $emailccuser = user-select "Username" $user2 #calls the userlookup function putting using the $user1 variable for the search
    }
    
    
    #asks for helpdesk ticket number if helpdesk is a recipient of the report
    if($emailuser.samaccountname -eq "helpdesk"){
        do{
        $hd_ticket = read-host "Helpdesk Ticket Number"
        }while (!($hd_ticket -match "^\d") -and ($hd_ticket -ne ""))
    } 
    if($hd_ticket -ne $null){$hd_ticket = "##$hd_ticket##"}
    
    
    #for reports with cc but no attachments
    if($user2 -ne "" -and $attachment -eq $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject "$subject $hd_ticket"`
        -cc $emailccuser.UserPrincipalName `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Encoding ([System.Text.Encoding]::UTF8)
    }
    
    #for reports not cc'd. Checks if there is a value for $user1 and no value for $user2
    if($user1 -ne "" -and $user2 -eq "" -and $attachment -eq $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject "$subject $hd_ticket" `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Encoding ([System.Text.Encoding]::UTF8)
    }
    
    #for reports with CC but has attachments
        if($user2 -ne "" -and $attachment -ne $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject "$subject $hd_ticket" `
        -cc $emailccuser.UserPrincipalName `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Attachments $($attachment.fullname) `
        -Encoding ([System.Text.Encoding]::UTF8)
    }
    
    #for reports not cc'd. Checks if there is a value for $user1 and no value for $user2
    if($user1 -ne "" -and $user2 -eq "" -and $attachment -ne $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject "$subject $hd_ticket" `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Attachments $($attachment.fullname) `
        -Encoding ([System.Text.Encoding]::UTF8)
    }
    return $null
}

<#
Summary:		Searches AD for a groups. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		no parameter
Return:			Returns the groups from the $options array that was chosen.
#>
function Group-Select
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    [string]$descrip
)
    #supresses error reporting to the screen
    $error.clear() #clears error log
    $erroractionpreference = "SilentlyContinue"
    
    do{
    $gname = read-host $descrip #asks for string. $descrip is a parameter could be user name, requestor, etc
    $gname_star=$gname+="*" #adds a * to the $uname variable to facilitate the "Name - like $uname_star" search
    [array]$options = Get-ADgroup -Filter {(Name -like $gname)} #looks for group name
        if($options -eq $null){write-host "I think you know what the problem is just as well as I do"} #outputs witty comment when group can't be found
    }while($options -eq $null)
    $displayProperty = "Name"
    $displayProperty2 = "GroupCategory"
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
            Write-Host ("{0,3}: {1} ({2})" -f $optionPrefix,$option.$displayProperty,$option.$displayProperty2)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"Exit") 
    
    #verifies that the user input is in a valid format
    do{
    [int]$response = Read-Host "Enter Selection"
    } while (!($response -match "^\d") -or ($response -gt $options.count))
    
    
    $val = $null
    if ($response -gt 0 -and $response -le $options.Count)
    {
        $val = $options[$response-1]
    }
    elseif ($response = 0)
    {
        exit
    }
    return $val
}

<#
Summary:		Creates a menu from an array that is passed to it. This array is intended to only contain strings.
Parameters:		$options is an array of strings. $Displayproperty is not used in this function.
Returns:		Returns the selected string from the [array]$options
#>	
function item-select{
PARAM 
(
    [Parameter(Mandatory=$true)]
    [array]$options,
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
    Write-Host ("{0,3}: {1}" -f 0,"Done") 
    [int]$response = Read-Host "Enter Selection"
    $val = $null
    if ($response -gt 0 -and $response -le $options.Count)
    {
        $val = $options[$response-1]
    }
    return $val
}  

<#
Summary:		Searches AD for a computer. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 computer.
Parameters:		no parameter
Return:			Returns the member from the $options array that was chosen.
#>
function computer_select
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    [string]$descrip
)
    do{
    $Cname = read-host $descrip #asks for string. $descrip is a parameter could be user name, requestor, etc
    $Cname_star=$Cname+="*" #adds a * to the $Cname variable to facilitate the "Name - like $Cname_star" search
    [array]$options = Get-ADComputer -Filter {((Name -like $Cname) -or (Name -like $Cname_star)) -and (Enabled -eq "True")}`
				#searches AD for the computer name
        if($options -eq $null){write-host "I think you know what the problem is just as well as I do"} #outputs witty comment when user can't be found
    }while($options -eq $null)
    $displayProperty = "Name"
    $displayProperty2 = "DNSHostName"
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
            Write-Host ("{0,3}: {1} ({2})" -f $optionPrefix,$option.$displayProperty,$option.$displayProperty2)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"Exit") 
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
    return $val
}  