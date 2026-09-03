# Identity Access Review
# Phase 5 - Identity Governance / Access Reviews
# Read-only reporting script for Active Directory review candidates

Import-Module ActiveDirectory

$InactiveDays = 60
$InactiveDate = (Get-Date).AddDays(-$InactiveDays)

$Users = Get-ADUser -Filter * -Properties Enabled,Department,Title,LastLogonDate,PasswordLastSet,WhenCreated,DistinguishedName

$ReviewCandidates = $Users |
    Where-Object {
        $_.Enabled -eq $true -and
        (
            ($_.LastLogonDate -and $_.LastLogonDate -lt $InactiveDate) -or
            (-not $_.LastLogonDate -and $_.WhenCreated -lt $InactiveDate)
        )
    }

$AccessReview = foreach ($User in $ReviewCandidates) {

    $Groups = (Get-ADPrincipalGroupMembership -Identity $User.SamAccountName).Name

    if ($Groups | Where-Object { $_ -ne "Domain Users" }) {
        $ReviewStatus = "REVIEW"
    }
    else {
        $ReviewStatus = "LOW ACCESS"
    }

    [PSCustomObject]@{
        SamAccountName  = $User.SamAccountName
        Department      = $User.Department
        Title           = $User.Title
        Enabled         = $User.Enabled
        LastLogonDate   = $User.LastLogonDate
        PasswordLastSet = $User.PasswordLastSet
        WhenCreated     = $User.WhenCreated
        Groups          = ($Groups -join ", ")
        ReviewStatus    = $ReviewStatus
    }
}

$ReportPath = "C:\AD-Lab\Phase5\IdentityAccessReview.csv"

if ($AccessReview) {
    $AccessReview | Export-Csv -Path $ReportPath -NoTypeInformation
}
else {
    'SamAccountName,Department,Title,Enabled,LastLogonDate,PasswordLastSet,WhenCreated,Groups,ReviewStatus' |
        Set-Content -Path $ReportPath
}

Write-Host "Access review complete. Report saved to: $ReportPath"
