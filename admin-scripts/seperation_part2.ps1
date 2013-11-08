<#
----------------------------------------------------
Title: Account Seperation Part 2
Author: Michael Mayer
Description: This code is designed to automate and standardize the acount disabling process.
Created: 10-18-2011
----------------------------------------------------
#>


<#
Summary:		Searches AD for a user. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		no parameter
Return:			Returns the member from the $options array that was chosen.
#>
function user_select
{
    do{
    $uname = read-host "Username" #asks for usernamename
    $uname_star=$uname+="*" #adds a * to the $uname variable to facilitate the "Name - like $uname_star" search
    [array]$options = Get-ADUser -Filter {((SamAccountName -like $uname) -or (GivenName -like $uname) -or (Surname -like $uname) -or (Name -like $uname_star)) -and (Enabled -eq "True")}`
				#searches AD for the username, givenname, surname, or login
        if($options -eq $null){write-host "I think you know what the problem is just as well as I do"} #outputs witty comment when user can't be found
    }while($options -eq $null)
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
    elseif ($response -eq 0)
    {
        exit
    }
    return $val
}    


<#
Summary:		Gets the DN of a particular user
Parameters:		$SAMName is the user SamAccountName
Return:			Returns the CN of the SamAccountName
#>
function get-dn ($SAMName)    {
    $root = [ADSI]''
     $searcher = new-object System.DirectoryServices.DirectorySearcher($root)
    $searcher.filter = "(&(objectClass=user)(sAMAccountName= $SAMName))"
    $user = $searcher.findall()
return $user[0].path
}

<#
Summary:		Gets username of the person running the script
Parameter:		No Parameters needed
Return:			Returns username
#>
function curuser #this function gets the AD information for the user who is running this script
{
$username = $env:username
$cuser = get-aduser -identity $username
return $cuser
}

import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD
Write-Host "Establishing Connection ucrx-ex-03"
$session = new-pssession -configurationName Microsoft.Exchange -ConnectionUri http://ucrx-ex-03/Powershell/ -Authentication Kerberos #establishes connection to the exchange server using current users credentials
Import-PSSession $session -allowClobber | Out-Null #imports remote powershell cmdlets to local powershell. Allowclobber suppresses an error if the cmdlets for exchange have already been imported

$cuser = curuser #gets the current user

#Gets username
$uname_result = user_select #gets username
if($uname_result -eq $null){ #exits program if no user is selected
    Remove-PSSession $Session
    exit
    } 
    
$path = get-dn $($uname_result.SamAccountName) #calls function get DN to get the DN of $uname_result

#Gets helpdesk ticket number
do{
    $hd = read-host "Helpdesk Ticket Number (Enter 0 to Exit)" #asks for helpdesk number
} while (!($hd -match "^[0-9]\d+")) #verifies that the number is a number and not a letter, space, or other garbage
if($hd -eq 0){ #exits program if no user is selected
    Remove-PSSession $Session #kills exchange session
    exit
    } 
#confirms with the user the account is to be disabled
$rand = New-Object system.random #initializes random numerber
$code = $rand.next(1000,9999) #generates randnumber
do{
    Write-host "Confirm Deletion of $($uname_result.Name)
    Account Name: $($uname_result.SamAccountName)"
    $verify = read-host "Enter Confirmation $code (press c to cancel)"
    if ($verify -eq "c"){exit;Remove-PSSession $Session} #exit if c is pressed. Kills exchange connection
} while ($code -ne $verify) #keeps in loop until c is pressed or confirmed

$mailtest = get-user -Identity $($uname_result.SamAccountName) | select RecipientType #gets information on the mailbox. Don't care what information. basically checking to see if the mailbox exist.
    if ($($mailtest.RecipientType) -ne "userMailbox"){ #if there is no value for $mailtest then the script will let the user know
        write-host "Mailbox $($uname_result.SamAccountName) does not exist" 
    }
    elseif ($($mailtest.RecipientType) -eq "userMailbox"){ #if the mailbox exists it will run the command below.
        disable-mailbox -Identity $($uname_result.SamAccountName) #disables the users mailbox
        write-host "Mailbox $($uname_result.SamAccountName) has been disabled"
   }
   
$account=[ADSI]$path #sets $account variable equal to the DN of the user
$account.psbase.invokeset("AccountDisabled", "True") #disbles account
$account.setinfo()

$MoveToOU = [ADSI]("LDAP://OU=Disabled,DC=ucx,DC=ucr,DC=edu")
$account.PSBase.moveto($MoveToOU)


write-host "Waiting for Domain Controllers to Replicate"
for ($i = 20; $i -gt 0;$i--) #countdown waiting for DCs to replicate
{
    write-host $i
    start-sleep -seconds 1
}

#this gets information about the user to email to helpdesk
$uinfo = get-aduser -identity $uname_result -Properties * | Select-Object -Property Name,SamAccountName,Description,EmailAddress,LastLogonDate,Manager,Title,Department,whenCreated,Enabled,Organization | Sort-Object -Property Name
$new_dn = get-dn $($uname_result.SamAccountName)

#Sends an email to helpdesk
$emailFrom = "no-reply@ucx.ucr.edu"
$emailTo = "helpdesk@ucx.ucr.edu"
$subject = "##$HD##"
$body = "DIT Preparer: $($it_prep.Name) `n`n $new_dn`n`n" + $uinfo #this includes lots of user info and their former group memberships
$smtpServer = "192.168.10.21"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)
   
write-host "Seperation Complete"
Remove-PSSession $Session #disconnects from ucrx-ex-03