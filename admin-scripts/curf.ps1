<#
----------------------------------------------------
Title: CURF
Author: Michael Mayer
Description: This code is designed to automate and standardize the acount creation process
Created: 10-18-2011
----------------------------------------------------
#>

import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

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
    [string]$descrip
)
    do{
    $uname = read-host $descrip #asks for string. $descrip is a parameter could be user name, requestor, etc
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
    elseif ($response = 0)
    {
        exit
    }
    return $val
}

<#
Summary:		Creates a random password in the format of Unex_XXXX where XXXX are random digits.
Parameters:		String. This is the prefix for the passowrd before the random four digits
Return:			Returns string+random 4 digits
#>
function pass([string]$a) #this function generates a password using a string provided followed by 4 random numbers
    {
        $rand = New-Object system.random
        $b = New-Object system.random
        $password = $a+$rand.next(1000,9999) #puts the $pass string and random number together
        #write-host "Password:$password" ##Writes password to screen. Not necessary. Used for testing
        return $password
    }


<#
Summary:		Creates a menu from an array that is passed to it. This array is intended to only contain strings.
Parameters:		$options is an array of strings. $Displayproperty is not used in this function.
Returns:		Returns the selected string from the [array]$options
#>	
function Select-TextItem
{
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
Summary:		Checks to see if a particular username exists
Parameters:		[string]$username
Return:			True or False
#>
function uname_exist ([string]$username)
{
    return ([boolean](Get-ADUser -Filter {SamAccountName -eq $username}))
}

<#
Summary:		Searches for all groups starting out with a particular string. All the while excluding a particular
Parameters:		$AD_cat needs to be either "security" or "distribution". $AD_filter what to filter for EX IEP*. 
				$DN_not the DN to be excluded. Usually used to exclude the printer OU.
Return:			Returns array of groups based on Paramters
#>
function ADQ_ouExc #this function user the AD category, Name, and OU to filter results. It does not return results within the OU supplied
{
PARAM
(
    $AD_cat, #ex "security" or "distribution"
    $AD_filter, #name filter should be like "IEP*"
    $DN_not #excluded OU. Must be OU=foo,DN=example,DN=Net
)
	$DN_notStar = "*"+$DN_not
	$ADQ1 = Get-ADGroup -Filter {(GroupCategory -eq $AD_cat) -and (Name -like $AD_filter)} -SearchBase "DC=ucx,DC=ucr,DC=EDU" `
				| Where-Object {$_.DistinguishedName -notlike $DN_notStar}
	return $ADQ1
}

<#
Summary:		Takes input in the form of an arraylist. Diplays it in a menu. Allows user to select item.
				Redisplays list with previously selected item gone
Parameters:		$options MUST BE AN ARRAYLIST!! To create arraylist $foo = New-Object System.Collections.ArrayList(,(cmd-let))
				Displayproperty is the member function to display
Return:			Returns an Array of the selected items.
#>
function multi_select_menu
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    $options,
    $displayProperty
)
    # Create menu list
   $val = New-Object System.Collections.ArrayList
do
{
    [int]$optionPrefix = 1
    foreach ($option in $options)
    {
        if ($displayProperty -eq $null)
        {
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option)
        }
        else
        {
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option.$displayproperty)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"Done") 
    $response = Read-Host "Enter Selection"
 if ($response -gt 0 -and $response -le $options.Count)
    {
        [void]$val.Add($options[$response-1]) #this void prevents the index value to put returned.
        $options.Remove($options[$response-1])
        
    }
	$vala = $val.ToArray() #converts $val, which is an arraylist to an array. This allows the memberfunction .count to work. Because the [void] on the arraylist strips the index number off
}
while ($response -ne 0)
    return $vala
} 

<#
Summary:		Verifies date format
Parameter:		String
Return:			Returns a verified data
#>
function date #function to verify date matches MM-DD-YYYY format
{
   do{
    $date = Read-host "Date (MM-DD-YYYY)"
   } while (!($date -match "^(0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.](19|20)\d\d$"))
 return $date
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
 
$first_name = read-host "First Name" #gets users first name
$middle_initial = ""
do{
	$middle_initial = read-host "Middle Initial"
}while ($middle_initial.length -gt 1) #this limits the middle initial to 0 or 1 character, but sending the user back to enter middle initial if the middle initial is great than 1
$last_name = read-host "Last Name" #gets last name

#puts together the full name of the user. Used to set display name in creation of the user account.
if ($middle_initial -ne ""){
    $full_name = "$first_name $middle_initial $last_name"
    }
    else{$full_name = "$first_name $last_name"}
    
    
$work_title = read-host "Working Title" #gets title

$start_date = date #gets start date
 
$empTypes = "Student","Staff","Contract","Volunteer","By Agreement" #Defines array of the different types of employment
$empType = Select-TextItem $empTypes "DisplayName" #calls Select-TextItem to allow the user to select the type of employment

$description = read-host "Description (Internal Use Only)" #gets value for $description

$username = $first_name.substring(0,1) + $last_name #sets username as First Initial + last name
$username = $username.ToLower() #makes username lowercase
$uname_exist #defines variable before calling function
$uname_exist = uname_exist($username) #calls uname_exist
if (uname_exist($username)) #checks to see if the username exists
{
$n=1
    do{
    $n++
    $username = $first_name.substring(0,$n) + $last_name 	#takes the substring from first_name starting position 0 through $n. 
															#If the username exists it runs the loop again with n++
    $username = $username.ToLower() #makes username lowercase
    }while (uname_exist($username)) #exits one uname_exists returns false
}
$uname_conf = read-host "Use username: $username (Y/N)?" #confirms generated username
while ($uname_conf -ne "y") #provides a chance to change the username
{
    $username = read-host "Enter Alternative Username" #since $uname_conf does not equal y the there is a prompt to change the username
    if (uname_exist($username)) #if username exists tells user to choose another
      {
        do{
        write-host "Username already exists"
        $username = read-host "Enter Alternative Username" #gets alternative username
        uname_exist($username) | out-null #checks if username exists
        }
        while (uname_exist($username)) #does not let user out of loop until they have chosen a non-existing username
      }
    $username = $username.ToLower() #makes username lowercase
    $uname_conf = read-host "Use username: $username (Y/N)?" #if anything but y is chosen it loops back to the username generation process
}
 
$password #define password variable for use with pass function
$password = pass("Unex_") #calls function to generate password
$password_plain = $password 
$password = convertto-securestring $password -asplaintext -force #converts password to a secure string. This is for the new-aduser command

$depts = "DEAN", "MKT", "BET","IEP","DIT","BUS","ART","PUB","SLH", "STU", "EDU" #this is the list of departments
$dept = Select-TextItem $depts "DisplayName" #calls Select-TextItem  
$dept_sg = $dept+"-SG" #this changes the dept name to the name of the value of its associated security group. This value is used to add the user to a security group.

do {
$pn = read-host "Enter a Phone Number
(55555)
(555-555-5555) 
or 0 for no number" #asks for phone number
} while (!($pn -match "\b\d{5}\b") -and !($pn -match "\b\d{3}-\d{3}-\d{4}") -and !($pn -like "0")) #checks to see if phone number is either 0, 5 digits, or 9 digits
if ($pn -like "0") {$pn=""} #if the phone number is 0 it sets the phone number to null

do
{
$room = read-host "Room Number (XXX)" #asks for room number
} while (!($room -match "\b\d{3}\b") -and !($room -match "BASE") -and !($room -match "")) #checks to see if room number matches XXX format or BASE

#asks for supervisors name.
do{
    $sup_result = user_select "Enter Supervisors Name"
} while($sup_result -eq $null) #keeps in loop until supervisor is chosen

#asks for requestors name.
do{
    $req_result = user_select "Enter Requestors Name"
} while($req_result -eq $null) #keeps in loop until requestor is chosen

$dept_star = $dept+"*" #adds start to $dept for next search query
$ad_sg = New-Object System.Collections.ArrayList(,(ADQ_ouExc "security" $dept_star "OU=Printer Groups,OU=Security Groups,OU=Domain Users,DC=ucx,DC=ucr,DC=edu"))`
		#calls function to filter AD for security groups that begin with the departments name and exclude the OU=Printer Groups
[array]$users_sg = multi_select_menu $ad_sg "Name" #calls the multi_select_menu function to collect the different security groups the user will belong to. must be array or it breaks the add-adgroupmember loop

#This block takes care of adding the user to q2_users
do{
    $q2 = read-host "Q2 Account? (Y/N)"
}while (!(($q2 -eq "y") -or ($q2 -eq "n")))

Write-Host "Establishing Connection ucrx-ex-03"
$session = new-pssession -configurationName Microsoft.Exchange -ConnectionUri http://ucrx-ex-03/Powershell/ -Authentication Kerberos #establishes connection to the exchange server using current users credentials
Import-PSSession $session -allowClobber | Out-Null #imports remote powershell cmdlets to local powershell. Allowclobber suppresses an error if the cmdlets for exchange have already been imported

#Gets response to see if the user is getting an email account
do{
$email = read-host "Exchange Account? (Y/N)"
}while (!(($email -eq "y") -or ($email -eq "n"))) #loops until valid response is received
 
if ($email -eq "y")
{
    $dg_search = New-Object System.Collections.ArrayList(,(Get-ADGroup -Filter {(GroupCategory -eq "distribution")} | Sort Name))  #retrieves all distribution groups from AD
    [array]$dg = multi_select_menu $dg_search "Name" #calls multi_select_menu so the user is given a list of distribution groups to choose from. Must be an array for the following loop breaks
}

$it_prep = curuser #calls curuser function

#writes out all the information about the user before committing it.
write-host "Name: $full_name
Username: $username
Password: $password_plain
Title: $work_title
Q2 Account: $q2
Employment Type: $empType
Starte Date: $start_date
Department: $dept
Phone Number: $pn
Room: $room
Supervisor: $($sup_result.Name)
Requestor: $($req_result.Name)
Description: $dept $empType $description
Distribution Groups:"
for ($i = 0; $i -lt $dg.count;$i++){ #this loop uses all the values selected in $dg and  writes them to the screen
      Write-host $dg[$i].name
}
Write-host "Security Groups:
Extension Staff
$dept_sg"
for ($i=0; $i -lt $users_sg.count;$i++){ #this loop uses the values selected in $users_sg and writes them to the screen
        write-host $users_sg[$i].name
}

do{
    $commit = read-host "Commit (Y/N)" #asks if the information about the user is correct
   }
   while (!(($commit -eq "y") -or ($commit -eq "n"))) #loops looking for a y or n
   
if ($commit -eq "y") #this is where the account actually gets created
{
$username2=$username+"@ucx.ucr.edu" #used for the new-aduser command. Could not get @ucx.ucr.edu to augment onto the variable $username
new-aduser -UserPrincipalName $username2 -name $full_name -SamAccountName $username -GivenName $first_name -Surname $last_name -DisplayName "$full_name" `
-Title $work_title -office $room -Company "University of California Riverside Extension" -OfficePhone $pn -Manager $sup_result.SamAccountName `
-Description "$dept $empType $description" `
-Department $dept -AccountPassword $password -ChangePasswordAtLogon 1 -Path 'cn=Users,dc=ucx,dc=ucr,dc=edu' -enabled 1 #this creates the account

Add-ADGroupMember -identity "Extension Staff" -member $username #adds user to extension staff
Add-ADGroupMember -Identity $dept_sg -member $username # adds user to departments security group
for ($i=0; $i -lt $users_sg.count;$i++) #adds user to all the selected security groups
{
        Add-ADGroupMember -Identity $users_sg[$i].name -member $username
}
    
if ($q2 -eq "y") {Add-ADGroupMember -identity "q2_Users" -member $username} #adds user to q2_users

write-host "Waiting 10 Seconds for Active Directory Replication"
start-sleep -seconds 10 #slows down script so exchange server can realize the AD account just created exists

if ($email -eq "y") #if the user is suppose to get an email address it creates it here.
    {
    enable-mailbox -identity $username2 -Database "Mailbox Database 1623792863" | Out-Null #creates mailbox
    if ($emptype -eq "Student") {Set-Mailbox -identity $username2 -IssueWarningQuota 157286400 -ProhibitSendQuota 183500800 -ProhibitSendReceiveQuota 209715200 -UseDatabaseQuotaDefaults $false} #if $emptype of Student it sets the student mailbox limits
    } #enables mailbox for the user if the previous response was yes for an email account

for ($i = 0; $i -lt $dg.count;$i++) #this loop uses all the values selected in $dg and puts the user into all those distribution groups
    {
      Add-ADGroupMember -Identity $dg[$i].name -member $username
     }
}
elseif($commit = "n"){
    Remove-PSSession $Session #disconnects from ucrx-ex-03
    exit  #exits the script if commit is No
}

#this whole block of code preparerss the email to helpdesk
$emailFrom = "$($req_result.UserPrincipalName)"
$emailTo = "helpdesk@ucx.ucr.edu"
$subject = "@SDP@ CURF - [$full_name]"
$body = "Name: $full_name
Start Date: $start_date
Username: $username
Password: $password_plain
Q2 Account: $q2
Employment Type: $empType 
Room Number: $room
Distribution Groups:"
for ($i = 0; $i -lt $dg.count;$i++) #this loop uses all the values selected in $dg and puts the user into all those distribution groups
    {
      $body+$($dg[$i].name) > $null #piped to null because it was outputting shit to the console.
     }
$body = $body+"
Security Groups:
"
for ($i=0; $i -lt $users_sg.count;$i++)
    {
        $body+$users_sg[$i].name > $null #piped to null because it was outputting shit to the console.
    }
$body = $body+"DIT Preparer: $($it_prep.Name)
@@MODE=CURF@@
@@PRIORITY=AFFECTS USER@@
@@CATEGORY=DOMAIN ACCOUNT@@"
$smtpServer = "192.168.10.21" #defines smtp server
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body) #sends email with the about parametes

Remove-PSSession $Session #disconnects from ucrx-ex-03
