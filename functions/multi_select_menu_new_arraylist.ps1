import-module ActiveDirectory
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


$values = New-Object System.Collections.ArrayList(,(Get-ADGroup -Filter {(GroupCategory -eq "Security") -and (Name -like "IEP*")} -SearchBase "DC=ucx,DC=ucr,DC=EDU" | Where-Object {$_.DistinguishedName -notlike "*OU=Printer Groups,OU=Security Groups,OU=Domain Users,DC=ucx,DC=ucr,DC=edu"}))
[array]$foo = multi_select_menu $values "Name"
#$foo | Format-List *
#$foo | get-member
$foo.count

