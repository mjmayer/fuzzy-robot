<#
Summary:		Searches AD for a user. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		no parameter
Return:			Returns the member from the $options array that was chosen.
#>
function user_select
{
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

<#
Summary:		Searches AD for a user. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		$subject (subject of the email), $bodyvar (body of the email), $attachment (Get-ChildItem "c:\temp\temp.txt")
Return:			nothing
#>
function email_report
{
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
        $emailuser = user_select "Username" $user1 #calls the userlookup function putting using the $user1 variable for the search
    }

    #asks for CC on email
    if($emailuser -ne ""){
        $user2 = read-host "Username for CC on Email Report (leave blank for no email)"
    }

    if($user2 -ne ""){
        $emailccuser = user_select "Username" $user2 #calls the userlookup function putting using the $user1 variable for the search
    }
    
    #for reports with cc but no attachments
    if($user2 -ne "" -and $attachment -eq $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject $subject `
        -cc $emailccuser.UserPrincipalName `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Encoding ([System.Text.Encoding]::ASCII)
    }
    
    #for reports not cc'd. Checks if there is a value for $user1 and no value for $user2
    if($user1 -ne "" -and $user2 -eq "" -and $attachment -eq $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject $subject `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Encoding ([System.Text.Encoding]::ASCII)
    }
    
    #for reports with CC but has attachments
        if($user2 -ne "" -and $attachment -ne $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject $subject `
        -cc $emailccuser.UserPrincipalName `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Attachments $($attachment.fullname) `
        -Encoding ([System.Text.Encoding]::ASCII)
    }
    
    #for reports not cc'd. Checks if there is a value for $user1 and no value for $user2
    if($user1 -ne "" -and $user2 -eq "" -and $attachment -ne $null){
        send-mailmessage -to $emailuser.UserPrincipalName `
        -from “No-Reply <no-reply@ucx.ucr.edu>“ `
        -Subject $subject `
        -body $bodyvar `
        -smtpserver 192.168.10.21 `
        -Attachments $($attachment.fullname) `
        -Encoding ([System.Text.Encoding]::ASCII)
    }
    return $null
}

$foo = Get-ChildItem "c:\temp\temp.txt"
email_report "subject" "foo!" $foo