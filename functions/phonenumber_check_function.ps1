do {
$pn = read-host "Enter a Phone Number
(55555)
(555-555-5555) 
or 0 for no number"
} while (!($pn -match "\b\d{5}\b") -and !($pn -match "\b\d{3}-\d{3}-\d{4}") -and !($pn -match "0"))
if ($pn -match "0") {$pn=""}