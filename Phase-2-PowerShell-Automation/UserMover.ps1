Import-Module ActiveDirectory

$Changes = Import-Csv "C:\AD-Lab\Phase2\EmployeeChanges.csv"

# Logging
$LogFolder = "C:\AD-Lab\Phase2\Logs"
$MoverLogFile = Join-Path -Path $LogFolder -ChildPath "MoverLog.csv"

function Write-MoverLog {
    param ($Username,$OldDepartment,$NewDepartment,$OldJobTitle,$NewJobTitle,$Status)
    $LogEntry = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Username = $Username
        OldDepartment = $OldDepartment
        NewDepartment = $NewDepartment
        OldJobTitle = $OldJobTitle
        NewJobTitle = $NewJobTitle
        Status = $Status
    }
    $LogEntry | Export-Csv -Path $MoverLogFile -Append -NoTypeInformation
}

$DepartmentOUs = @{
    "HR" = "OU=HR,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "IT" = "OU=IT,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "Sales" = "OU=Sales,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "Management" = "OU=Management,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "Gaming" = "OU=Gaming_Users,OU=Users,OU=Trey's Company,DC=lab,DC=local"
}
$DepartmentGroups = @{
    "HR" = "HR_Users"
    "IT" = "IT_Admin"
    "Sales" = "Sales_Users"
    "Management" = "Managers"
    "Gaming" = "Gaming_Admin"
}

$Changes | ForEach-Object {
    $Username = $_.Username
    $NewDepartment = $_.NewDepartment
    $NewJobTitle = $_.NewJobTitle
    $NewOU = $DepartmentOUs[$NewDepartment]
    $NewGroup = $DepartmentGroups[$NewDepartment]

    $User = Get-ADUser -Identity $Username -Properties Department,Title,MemberOf -ErrorAction SilentlyContinue
    if (-not $User) { Write-Host "ERROR: User $Username was not found."; return }

    $OldDepartment = $User.Department
    $OldJobTitle = $User.Title
    $OldGroup = $DepartmentGroups[$OldDepartment]
    if (-not $NewOU -or -not $NewGroup) { Write-Host "ERROR: Invalid department for $Username"; return }

    try {
        Set-ADUser -Identity $Username -Department $NewDepartment -Title $NewJobTitle -ErrorAction Stop
        if ($OldGroup -and $OldGroup -ne $NewGroup) {
            Remove-ADGroupMember -Identity $OldGroup -Members $Username -Confirm:$False -ErrorAction Stop
        }
        Add-ADGroupMember -Identity $NewGroup -Members $Username -ErrorAction Stop
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $NewOU -ErrorAction Stop
        Write-MoverLog -Username $Username -OldDepartment $OldDepartment -NewDepartment $NewDepartment -OldJobTitle $OldJobTitle -NewJobTitle $NewJobTitle -Status "SUCCESS"
        Write-Host "SUCCESS: Moved $Username from $OldDepartment to $NewDepartment"
    }
    catch {
        Write-Host "ERROR: Could not move $Username"
        Write-Host $_.Exception.Message
        Write-MoverLog -Username $Username -OldDepartment $OldDepartment -NewDepartment $NewDepartment -OldJobTitle $OldJobTitle -NewJobTitle $NewJobTitle -Status "ERROR"
    }
}
