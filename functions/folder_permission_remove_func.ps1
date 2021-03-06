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
change_acl "\\ucrxfs02\archive\STU\Separated_Employees\STU-EBC-SG\jromero\" "stu-sg" "modify"