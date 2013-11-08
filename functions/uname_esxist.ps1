function uname_exist ([string]$username)
{
if( -not(Get-ADUser -Filter {SamAccountName -eq $username}))
    {
    $uname_exist = 0
    }
else
    {
    $uname_exist = 1
    }
return $uname_exist
}
$uname_exist = uname_exist("mmayer")
write-host $uname_exist