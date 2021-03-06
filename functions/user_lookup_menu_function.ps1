import-module ActiveDirectory

function selectitem
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
            Write-Host ("{0,3}: {1}" -f $optionPrefix,$option.$displayProperty)
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

$sup = read-host "Supervisor's Name"
$sup_star=$sup+="*"
[array]$sup_result = Get-ADUser -Filter {(SamAccountName -like $sup) -or (GivenName -like $sup) -or (Surname -like $sup) -or (Name -like $sup_star)}
$sup_val = selectitem $sup_result "Name"
$sup_val.(name)