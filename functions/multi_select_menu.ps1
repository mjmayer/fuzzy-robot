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


$values = "foo1", "foo2"

$foo = multi_select_menu $values #"Name"


