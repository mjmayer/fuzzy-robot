


<#
Summary:		Returns infomration about printers connected to a computer
Parameters:		Computer Name
Return:			Returns an array with a lot of information about every printer attached to the computer.
#>

function printer_info
{
PARAM 
(
    [Parameter(Mandatory=$true)]
    [string]$cname
)
$localp = Get-WmiObject -Class Win32_Printer -ComputerName $cname
$netp = (New-Object -ComObject WScript.Network).EnumPrinterConnections()
return $localp+$netp
}


$strcomp = Read-host "Enter computer name"
$pinfo = printer_info $strcomp