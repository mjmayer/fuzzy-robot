<#
Summary:		Takes an array and displays the values in it for selection by the user.
Parameters:		array of values and the display property name
Return:			Value selected
#>

function Select-TextItem
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    $options,
    $displayProperty
)

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
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option)
        }
        $optionPrefix++
    }
    Write-Host ("{0,3}: {1}" -f 0,"To cancel") 
    [int]$response = Read-Host "Enter Selection"
    $val = $null
    if ($response -gt 0 -and $response -le $options.Count)
    {
        $val = $options[$response-1]
    }
    return $val
}   

$values = "DEAN", "MKT", "BET","IEP","DIT","BUS","ART","PUB","SLH"
$val = Select-TextItem $values "DisplayName"
$val