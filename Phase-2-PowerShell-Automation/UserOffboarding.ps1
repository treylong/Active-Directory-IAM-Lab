Import-Module ActiveDirectory

$OffboardingUsers = Import-Csv "C:\AD-Lab\Phase2\EmployeeOffboarding.csv"
$DisabledOU = (Get-ADOrganizationalUnit -Filter 'Name -eq "Disabled_Users"').DistinguishedName

# Logging
$LogFolder = "C:\AD-Lab\Phase2\Logs"
$OffboardingLogFile = Join-Path -Path $LogFolder -ChildPath "OffboardingLog.csv"

function Write-OffboardingLog {
    param ($Username,$Department,$JobTitle,$Groups,$Status)
    $LogEntry = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Username = $Username
        Department = $Department
        JobTitle = $JobTitle
        Groups = $Groups
        Status = $Status
    }
    $LogEntry | Export-Csv -Path $OffboardingLogFile -Append -NoTypeInformation
}

$OffboardingUsers | ForEach-Object {
    $Username = $_.Username
    $User = Get-ADUser -Identity $Username -Properties Department,Title,MemberOf,Enabled -ErrorAction SilentlyContinue
    if (-not $User) { Write-Host "ERROR: User $Username was not found."; return }
    if (-not $User.Enabled) { Write-Host "SKIPPED: User $Username is already disabled."; return }

    $Department = $User.Department
    $JobTitle = $User.Title
    $CurrentGroups = (Get-ADPrincipalGroupMembership -Identity $Username | Where-Object { $_.Name -ne "Domain Users" } | Select-Object -ExpandProperty Name) -join ";"

    $TargetOU = Get-ADOrganizationalUnit -Identity $DisabledOU -ErrorAction SilentlyContinue
    if (-not $TargetOU) { Write-Host "ERROR: Disabled_Users OU was not found."; return }

    try {
        Disable-ADAccount -Identity $Username -ErrorAction Stop
        $GroupsToRemove = Get-ADPrincipalGroupMembership -Identity $Username | Where-Object { $_.Name -ne "Domain Users" }
        foreach ($Group in $GroupsToRemove) {
            Remove-ADGroupMember -Identity $Group.Name -Members $Username -Confirm:$False -ErrorAction Stop
        }
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU -ErrorAction Stop
        Write-OffboardingLog -Username $Username -Department $Department -JobTitle $JobTitle -Groups $CurrentGroups -Status "SUCCESS"
        Write-Host "SUCCESS: Offboarded $Username"
    }
    catch {
        Write-Host "ERROR: Could not offboard $Username"
        Write-Host $_.Exception.Message
        Write-OffboardingLog -Username $Username -Department $Department -JobTitle $JobTitle -Groups $CurrentGroups -Status "ERROR"
    }
}
