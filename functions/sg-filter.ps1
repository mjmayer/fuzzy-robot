import-module ActiveDirectory
[array]$sg = Get-ADGROUP -Filter {GroupCategory -eq "Security" -and Name -like "IEP*"} #| FT Name
$sg.Count
#$sgt = $sg[2,1+3..($sg.length - 2)]
#$sgt.count
#$sgt
write-host $sg
