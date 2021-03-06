<#
Summary:		Gets the DN of a particular user.
Parameters:		SamAccountName
Return:			DN of the Users.
#>
function get-dn ($SAMName)    {
    $root = [ADSI]''
     $searcher = new-object System.DirectoryServices.DirectorySearcher($root)
    $searcher.filter = "(&(objectClass=user)(sAMAccountName= $SAMName))"
    $user = $searcher.findall()
return $user[0].path
}
$foo = get-dn "dwossum"
$foo