function curuser
{
$username = $env:username
$cuser = get-aduser -identity $username
return $cuser
}
$foo = curuser
$foo