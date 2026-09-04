# Active Directory Audit Report
# Phase 6 - AD Auditing & Security Monitoring
# Read-only reporting script for Windows Security events

$EventIds = 4722,4724,4725,4728,4729

$ReviewDays = 30
$StartTime = (Get-Date).AddDays(-$ReviewDays)

$Events = Get-WinEvent -FilterHashtable @{
    LogName   = 'Security'
    Id        = $EventIds
    StartTime = $StartTime
} -MaxEvents 100

$AuditReport = foreach ($Event in $Events) {

    [xml]$Xml = $Event.ToXml()
    $Data = @{}

    $Xml.Event.EventData.ChildNodes | ForEach-Object {
        $Data[$_.GetAttribute("Name")] = $_.InnerText
    }

    $Action = switch ($Event.Id) {
        4722 { "Account Enabled" }
        4724 { "Password Reset" }
        4725 { "Account Disabled" }
        4728 { "Group Member Added" }
        4729 { "Group Member Removed" }
        default { "Unknown" }
    }

    if ($Event.Id -eq 4728 -or $Event.Id -eq 4729) {
        $Target = ""
        $Group  = $Data["TargetUserName"]
    }
    else {
        $Target = $Data["TargetUserName"]
        $Group  = ""
    }

    if ($Data["MemberName"]) {
        $Member = ($Data["MemberName"] -split ",")[0] -replace "^CN=",""
    }
    else {
        $Member = ""
    }

    [PSCustomObject]@{
        TimeCreated = $Event.TimeCreated
        EventID     = $Event.Id
        Action      = $Action
        Actor       = $Data["SubjectUserName"]
        Target      = $Target
        Member      = $Member
        Group       = $Group
    }
}

$ReportPath = "C:\AD-Lab\Phase6\Reports\ADAuditReport.csv"

$AuditReport |
    Sort-Object TimeCreated |
    Export-Csv -Path $ReportPath -NoTypeInformation

Write-Host "AD audit report complete. Report saved to: $ReportPath"
Write-Host "Events reviewed: $($AuditReport.Count)"
Write-Host "Review window: Last $ReviewDays days"
