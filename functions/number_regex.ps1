
do{
    $hd = read-host "Helpdesk Ticket Number"
} while (!($hd -match "^\d"))