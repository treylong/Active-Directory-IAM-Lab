# Active Directory User Provisioning
# Imports employee data from CSV, maps departments to OUs/security groups,
# creates missing AD accounts, and skips accounts that already exist.

Import-Module ActiveDirectory

$CsvPath = Join-Path $PSScriptRoot "NewEmployees-Sample.csv"
$Employees = Import-Csv $CsvPath

$DepartmentOUs = @{
    "HR"         = "OU=HR,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "IT"         = "OU=IT,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "Sales"      = "OU=Sales,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "Management" = "OU=Management,OU=Users,OU=Trey's Company,DC=lab,DC=local"
    "Gaming"     = "OU=Gaming_Users,OU=Users,OU=Trey's Company,DC=lab,DC=local"
}

$DepartmentGroups = @{
    "HR"         = "HR_Users"
    "IT"         = "IT_Admin"
    "Sales"      = "Sales_Users"
    "Management" = "Managers"
    "Gaming"     = "Gaming_Admin"
}

# Prompt at runtime so no password is stored in the script.
$Password = Read-Host "Enter temporary password for new employees" -AsSecureString

foreach ($Employee in $Employees) {
    $Username = ($Employee.FirstName.Substring(0,1) + $Employee.LastName).ToLower()
    $OU = $DepartmentOUs[$Employee.Departments]
    $Group = $DepartmentGroups[$Employee.Departments]

    if (-not $OU -or -not $Group) {
        Write-Host "ERROR: No OU/group mapping for department '$($Employee.Departments)' ($Username)"
        Write-Host "----------------------------------------"
        continue
    }

    $ExistingUser = Get-ADUser -Filter "SamAccountName -eq '$Username'"

    if ($ExistingUser) {
        Write-Host "SKIPPED: $Username already exists."
    }
    else {
        try {
            New-ADUser `
                -Name "$($Employee.FirstName) $($Employee.LastName)" `
                -GivenName $Employee.FirstName `
                -Surname $Employee.LastName `
                -SamAccountName $Username `
                -UserPrincipalName "$Username@lab.local" `
                -Department $Employee.Departments `
                -Title $Employee.JobTitle `
                -Path $OU `
                -AccountPassword $Password `
                -Enabled $true `
                -ChangePasswordAtLogon $true `
                -ErrorAction Stop

            Add-ADGroupMember `
                -Identity $Group `
                -Members $Username `
                -ErrorAction Stop

            Write-Host "SUCCESS: Created $Username and added to $Group"
        }
        catch {
            Write-Host "ERROR: Could not provision $Username"
            Write-Host $_.Exception.Message
        }
    }

    Write-Host "----------------------------------------"
}
