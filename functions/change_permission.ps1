#ChangePermissions.ps1
# CACLS rights are usually
# F = FullControl
# C = Change
# R = Readonly
# W = Write

$StartingDir= "C:\temp\foo"

$Principal="Users"

$Permission="F"

$Verify=Read-Host `n "You are about to change permissions on all" `
"files starting at"$StartingDir.ToUpper() `n "for security"`
"principal"$Principal.ToUpper() `
"with new right of"$Permission.ToUpper()"."`n `
"Do you want to continue? [Y,N]"

if ($Verify -eq "Y") {

foreach ($file in $(Get-ChildItem $StartingDir -recurse)) {
#display filename and old permissions
write-Host -foregroundcolor Yellow $file.FullName
#uncomment if you want to see old permissions
#CACLS $file.FullName

#ADD new permission with CACLS
CACLS $file.FullName /E /P "${Principal}:${Permission}" >$NULL

#display new permissions
Write-Host -foregroundcolor Green "New Permissions"
CACLS $file.FullName
}
}