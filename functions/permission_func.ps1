<#
Summary:		Changes permission on a given directory
Parameters:		location of files, username, rights
Return:			Returns the member from the $options array that was chosen.
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
change_acl "c:\temp\foo\" "dwossum" "modify"