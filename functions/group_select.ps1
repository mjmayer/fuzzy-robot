<#
Summary:		Searches AD for a groups. Gives a menu selection of the users that meet the criteria. Allows for the selection of 1 user.
Parameters:		no parameter
Return:			Returns the groups from the $options array that was chosen.
#>
function group_select
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    [string]$descrip
)
    do{
    $gname = read-host $descrip #asks for string. $descrip is a parameter could be user name, requestor, etc
    $gname_star=$gname+="*" #adds a * to the $uname variable to facilitate the "Name - like $uname_star" search
    [array]$options = Get-ADgroup -Filter {(Name -like $gname)}`
				#searches AD for the username, givenname, surname, or login
        if($options -eq $null){write-host "I think you know what the problem is just as well as I do"} #outputs witty comment when user can't be found
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
$foo = group_select "Group Name"
$foo