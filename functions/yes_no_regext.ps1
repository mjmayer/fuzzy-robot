
do{
    $foo = read-host "Enter Y or N"
} while (!($foo -match "^[yn]"))