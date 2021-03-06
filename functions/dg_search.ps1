function multi_select_menu
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    [array]$options,
    $displayProperty
)
    # Create menu list
    [array]$val = @()
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
    Write-Host ("{0,3}: {1}" -f 0,"To cancel") 
    [int]$response = Read-Host "Enter Selection"
 if ($response -gt 0 -and $response -le $options.Count)
    {
        $val += $options[$response-1]
    }
}
while ($response -ne 0)
    return $val
} 
$dg_search = Get-ADGroup -Filter {(GroupCategory -eq "distribution")} | Sort Name  #retrieves all distribution groups from AD
[array]$dg = multi_select_menu $dg_search "Name" #calls multi_select_menu so the user is given a list of distribution groups to choose from
for ($i = 0; $i -lt $dg.count;$i++) #this loop uses all the values selected in $dg and puts the user into all those distribution groups
    {
        #Add-ADGroupMember -Identity $dg[$i].name -member $username
        write-host $dg[$i].name -member
    }