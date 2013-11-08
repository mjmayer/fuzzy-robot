<#
Summary:		Generates password
Parameters:		string that defines the prefix on the password
Return:			Returns password
#>
function pass([string]$a) #this function generates a password using a string provided followed by 4 random numbers
    {
        $rand = New-Object system.random
        $b = New-Object system.random
        $password = $a+=$rand.next(1000,9999)
        #write-host "Password:$password"
        return $password
    }
    pass("Unex_")