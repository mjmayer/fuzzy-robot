function ADQ_ouExc
{
PARAM
(
    $AD_cat, #ex "security" or "distribution"
    $AD_filter, #name filter should be like "IEP*"
    $DN_not #excluded OU. Must be OU=foo,DN=example,DN=Net
)
$DN_notStar = "*"+$DN_not
$ADQ1 = Get-ADGroup -Filter {(GroupCategory -eq $AD_cat) -and (Name -like $AD_filter)} -SearchBase "DC=ucx,DC=ucr,DC=EDU" `
| Where-Object {$_.DistinguishedName -notlike $DN_notStar}
return $ADQ1
}

#$user_sg = ADQ_ouExc "security" "iep*" "OU=Printer Groups,OU=Security Groups,OU=Domain Users,DC=ucx,DC=ucr,DC=edu"
#$user_sg

#$EXAMPLE = ADQ_ouEXc "Security" "IEP*" "OU=Printer Groups,OU=Security Groups,OU=Domain Users,DC=ucx,DC=ucr,DC=edu"
#write-host $EXAMPLE

$search_DG = ADQ_ouExc "Distribution" "" ""