function date
{
   do{
    $date = Read-host "Date (MM-DD-YYYY)"
    } while (!($date -match "^(0[1-9]|1[012])[- /.](0[1-9]|[12][0-9]|3[01])[- /.](19|20)\d\d$"))
    
 return $date
 }
 $start_date = date