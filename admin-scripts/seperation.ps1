<#
----------------------------------------------------
Title: Account Separation Part 1
Author: Michael Mayer
Description: This code is designed to automate and standardize the acount seperation process
Created: 10-18-2011
----------------------------------------------------
#>
import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD
Write-Host "Establishing Connection ucrx-ex-03"
$session = new-pssession -configurationName Microsoft.Exchange -ConnectionUri http://ucrx-ex-03/Powershell/ -Authentication Kerberos #establishes connection to the exchange server using current users credentials
Import-PSSession $session -allowClobber | Out-Null #imports remote powershell cmdlets to local powershell. Allowclobber suppresses an error if the cmdlets for exchange have already been imported

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
Summary:		Creates a list menu from an array that was passed into it. Only one selection can be made from the list
Parameters:		$options an array containing information (most likely gotten from AD). $displayProperty are the choices displayed in the menu.
				$displayProperty is a member of the #options array.
Return:			Returns the member from the $options array that was chosen.
#>
function selectitem_1prop
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
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option.$displayProperty)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"To cancel") 
    [int]$response = Read-Host "Enter Selection"
    $val = $null
    if ($response -gt 0 -and $response -le $options.Count)
    {
        $val = $options[$response-1]
    }
    return $val
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

<#
Summary:		Changes permission on a given directory
Parameters:		location of files, username, rights
Return:			Returns nothing
#>
function change_acl
{
PARAM
(
    [parameter(Mandatory=$true)]
    $path,
    $username,
    $permissions
)

$acl = get-acl $path #retrieves current ACL on userdata\username
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("unex_admin\$($username)","modify","Allow") #specifies the new permissions
$Acl.SetAccessRule($Ar) #sets the ACL rules
Set-Acl -path $path -aclobject $acl
get-childitem $path -recurse -force | Set-Acl -aclobject $acl #applies ACL to userdata
$aclnew = get-acl $path

return $null
}

<#
Summary:		Removes permissions on a file
Parameters:		location of files, username, rights
Return:			Returns nothing
#>

function remove_acl
{
PARAM
(
    [parameter(Mandatory=$true)]
    $path,
    $username,
    $permissions
)

$acl = get-acl $path #retrieves current ACL on userdata\username
$Ar = New-Object  system.security.accesscontrol.filesystemaccessrule("unex_admin\$($username)","modify","Allow") #specifies the new permissions
$Acl.RemoveAccessRuleAll($Ar) #sets the ACL rules
Set-Acl -path $path -aclobject $acl
get-childitem $path -recurse -force | Set-Acl -aclobject $acl #applies ACL to userdata
$aclnew = get-acl $path

return $null
}

#VARIABLES FOR SCRIPT
$server = "ucrx-fs" #replace this is the fileshare server changes.
$udata_fileName = "userdata" #the specifies the name of folder were userdata is stored
$udataPath = "\\$($server)\$($udata_fileName)\" #this constructs the full UNC of the \\server\userdata
$archiveUNC ="\\ucrxfs02\archive" #defines archive UNCR

import-module ActiveDirectory #imports active directory module. Necessary for scripts interaction with AD

$cuser = curuser #gets the current user

#asks for account name
$uname_result = user_select "Enter Username"
if($uname_result -eq $null){ #exits program if no user is selected
    Remove-PSSession $Session
    exit
    } 

$MemberOf = (get-aduser -identity $uname_result -Properties MemberOf | Select-Object Memberof).MemberOf #gets a list of
$uinfo = get-aduser -identity $uname_result -Properties * | Select-Object -Property Name,SamAccountName,Description,EmailAddress,LastLogonDate,Manager,Title,Department,whenCreated,Enabled,Organization | Sort-Object -Property Name

#gets helpdesk ticker number
do{
    $hd = read-host "Helpdesk Ticket Number (Enter 0 to Exit)" #asks for helpdesk number
        if($hd -eq [int]0){ #exits program if no user is selected
            Remove-PSSession $Session #kills exchange session
            exit
            } 
} while (!($hd -match "^[0-9]\d+")) #verifies that the number is a number and not a letter, space, or other garbage


$group_mem=@() #initializes @memberof array. This will store our users SGs and DGs in a standard format
for ($i = 0; $i -lt $MemberOf.count;$i++) #loops for each object in $memeberof
{
    $group_mem += get-adgroup -identity $MemberOf[$i] #gets the users DGs and SGs into a standard format
}
if ($group_mem -eq $null){write-host -ForegroundColor red "This user does not belong to any security groups. They have probably already been seperated"}

$uprop = get-aduser -identity $uname_result -Properties * #gets all properites for the users AD account. This will be used to derive the primary SG for the user
if(!($uprop.Manager) -eq $null){write-host "User's Manager $($uprop.Manager.TrimStart('CN=').TrimEnd(',CN=Users,DC=ucx,DC=ucr,DC=edu')) "} #displays users managers name with some trimmage because the member Manager returns the full CN

if($group_mem -ne $null){
    write-host "Select Secondary Security Group Members. If no secondary Securtiy Group exists press 0" #tells user what they are going to select
    $secSG = selectitem_1prop $group_mem "Name" #gets secondary security group for use in the copying of userdata to a new location.
    }
$deptSG = $($uprop.Department)+"-SG" #defines $deptSG as the users AD department descriptor + "-sg". Giving the out of DEPT-SG ex stu-sg

$other_access = read-host "The Manager of the user is by default granted access to the files. Does anyone else need access? (Y/N)"
$extra_user=@()
if ($other_access -eq "Y"){
    do{
        $user1 = user_select "Additional user who needs access"
        $extra_user = $extra_user + $user1
        $add_yn = read-host "Additional Users (Y/N)"
            if ($add_yn -eq "y"){
                $user1 = user_select "Username for additional modify permissions"
                $extra_user = $extra_user + $user1
            $add_yn = read-host "Additional Users (Y/N)"
            }
    } while ($add_yn -ne "N")
}

#confirms with the user the account is to be deleated
$rand = New-Object system.random #initializes random numerber
$code = $rand.next(1000,9999) #generates randnumber
do{
    Write-host "Confirm Deletion of $($uname_result.Name)
    Account Name: $($uname_result.SamAccountName)"
    $verify = read-host "Enter Confirmation $code (press c to cancel)"
    if ($verify -eq "c"){Remove-PSSession $Session;exit} #exit if c is pressed
} while ($code -ne $verify) #keeps in loop until c is pressed or confirmed

$it_prep = curuser #calls curuser function

if (!(test-path "$($udataPath)\$($uname_result.SamAccountName)\")){write-host -ForegroundColor red "$($uname_result.SamAccountName) has no Userdata folder"}
if (test-path "$($udataPath)\$($uname_result.SamAccountName)\"){ #checks to see if the user even has a directory in userdata path
    #Test for desitnation of the users data. If it is not found it is created.
    if (test-path "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)") {write-host "Verifired Destination Folder for Userdata"}
        else {
            New-Item "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)" -type Directory #creates the directory
            write-host "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name) Created"
        }
    if (!(test-path "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)")) {
        Write-Host "Failed to create \\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)"
        exit #exits if the directory has failed to be created
    }
    takeown /s $server /f "$($udataPath)\$($uname_result.SamAccountName)\" /R /d Y #takes ownership of home directory
    $acl_comp = get-acl "$($udataPath)\$($uname_result.SamAccountName)\" #gets current acl. Used for comparison of own
    if ($acl_comp.owner -ne "UNEX_ADMIN\$($it_prep.SamAccountName)") {write-host "Could not verify that ownership was taken of the userdata" ; exit} #exists script if permissions could not be taken on the directory.

    
    #This explicity gives the person running the script full control over everything in the directory including hidden files. Takeown will not give permission on hidden files.
    change_acl "$($udataPath)$($uname_result.SamAccountName)" "$($cuser.SamAccountName)" "FullControl" #gives full control permissions on the seperated employees data to the person running th script
    start-sleep -second 3
    
    $man_sam = ([ADSI]"LDAP://$($uprop.manager)").samaccountname #gets manager samaccountname from AD
    
    Remove-item "$($udataPath)\$($uname_result.SamAccountName)\*" -include "*.bin" -recurse -force
    copy-item "$($udataPath)\$($uname_result.SamAccountName)\"  "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)" -recurse #moves userdata
    get-childitem -path "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\*" -include *RECYCLE.BIN -recurse | remove-item -recurse -force #gets rid of those fucking $RECYLE.BIN `
    #folders that get created when copying the recycle bin.
    $acl_sep = get-acl "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees" #retrieves ACL for seperated_emplyees directory
    get-childitem "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" -recurse -force | Set-acl -AclObject $acl_sep #applies permissions found on seperated_emploess directory to the`
        #copy of the userdata located on archive\department\sub_department_sg\uname.SamAccountName
    if ($man_sam -ne $null){ #only executes if the user has a manager set in AD
        change_acl "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" $man_sam "modify" #gives the manager of the employee modify access to userdata on archive.
        }
    elseif ($man_sam -eq $null){ #outputs that there is no manager set in AD
        write-host "No Manager set in AD. Will not apply permissions for the manager" 
        }
    for ($i = 0; $i -lt $extra_user.count;$i++) #this loop uses all the values selected in $dg and puts the user into all those distribution groups
        {
        change_acl "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" "$($extra_user[$i].samaccountname)" "modify" #gives the manager of the employee modify access to userdata on archive.
        }
    $acl_rem = get-acl "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" #retrieves acl on userdata folder on archive
    $acl_rem.SetAccessRuleProtection($true,$true) #set $acl object to block inheritance
    Set-Acl -path "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" -aclobject $acl_rem #Applies the ACL to block inheritance
    
    remove_acl "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" "$deptSG" "modify" #removes the dept-sg from the acl
            
    #gets all filenames in both directories and compares them. If they do not match it exist the script. If they do match the originals are deleted. 
    $d1 = get-childitem -path "$($udataPath)\$($uname_result.SamAccountName)\" -recurse
    $d2 = get-childitem -path "\\ucx.ucr.edu\fs\archive\$($uprop.Department)\Separated_Employees\$($secsg.name)\$($uname_result.SamAccountName)\" -recurse
    $compare = compare-object $d1 $d2
    if ($compare -ne $null) {
        write-host "Failed copy verification"
        exit
    }
    elseif ($compare -eq $null) {Remove-item "$($udataPath)\$($uname_result.SamAccountName)\" -recurse -force} #add -recurse to supress prompts. Forece deletes those blasted hidden files. TAKE THAT! HA
}
     
for ($i = 0; $i -lt $group_mem.count;$i++) #loop to remove user from all SG's and DG's
{
    remove-adgroupmember $group_mem[$i].Name $uname_result.SamAccountName -Confirm:$false #removes user from SG and DG
}

Set-ADuser -Identity $($uname_result.SamAccountName) -Description $null -OfficePhone $null -Manager $null -LogonWorkstations "ucrx-fe-01" #Removes description, Office Phone, manager.`
            #Set workstation logon to none locking the person out of all desktops

$mailtest = get-user -Identity $($uname_result.SamAccountName) | select RecipientType #get recipient type for users mailbox. Looking for type of "UserMailbox"
if ($($mailtest.RecipientType) -eq "userMailbox") { #if the RecipientType equals UserMailbox perform hide from GAL
    set-mailbox $($uname_result.SamAccountName) -HiddenFromAddressListsEnabled $true #hides mailbox from GAL
}

#Sends an email to helpdesk
$emailFrom = "no-reply@ucx.ucr.edu"
$emailTo = "helpdesk@ucx.ucr.edu"
$subject = "##$HD##"
$body = "DIT Preparer: $($it_prep.Name) `n`n $($group_mem)`n`n" + $uinfo #this includes lots of user info and their former group memberships
$smtpServer = "192.168.10.21"
$smtp = new-object Net.Mail.SmtpClient($smtpServer)
$smtp.Send($emailFrom, $emailTo, $subject, $body)

write-host "Seperation Complete"
Remove-PSSession $Session #disconnects from ucrx-ex-03

