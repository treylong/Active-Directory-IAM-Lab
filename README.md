# Active Directory Sysadmin & IAM Lab

A Windows Server / Active Directory home lab built to practice system administration, PowerShell automation, and identity lifecycle management.

## Project Overview

This project simulates a small company environment in the `lab.local` Active Directory domain. The lab includes organizational units, department security groups, fictional employee accounts, Group Policy, and PowerShell automation for the Joiner-Mover-Leaver (JML) identity lifecycle.

The goal is to move beyond GUI-only administration and practice repeatable, auditable identity-management workflows while validating changes in Active Directory Users and Computers (ADUC).

## Skills Demonstrated

- Windows Server and Active Directory Domain Services (AD DS)
- Active Directory Users and Computers (ADUC)
- Organizational Unit (OU) design and security groups
- Group Policy administration
- PowerShell and the ActiveDirectory module
- CSV-driven Joiner, Mover, and Leaver automation
- Department-to-OU and department-to-group mapping
- Duplicate and already-disabled account protection
- `try` / `catch` and `-ErrorAction Stop`
- Pre-validation before destructive account changes
- CSV audit logging
- OU, account-status, and group-membership verification

## Phase 1 — Active Directory Infrastructure

I built the Active Directory structure manually to understand the underlying administration before automating it. This included OUs, users, security groups, and Group Policy configuration.

![Active Directory OU and group structure](Phase-1-AD-Infrastructure/Screenshots/AD-Structure.png)

## Phase 2 — IAM Joiner, Mover, and Leaver Automation

### Joiner Workflow

`UserProvisioning.ps1` reads fictional employee records from `NewEmployees-Sample.csv`, generates usernames, maps departments to OUs/groups, checks for duplicates, creates missing accounts, sets attributes, requires password change at first logon, and assigns department security groups. The temporary password is requested at runtime and is not stored in this repository.

![PowerShell provisioning results](Phase-2-PowerShell-Automation/Screenshots/Provisioning-Results.png)

### Mover Workflow

`UserMover.ps1` processes department/job changes from `EmployeeChanges-Sample.csv`. It captures the previous state, validates the requested department, updates AD attributes, removes old department access, adds new department access, moves the account to the correct OU, and records SUCCESS/ERROR results in a CSV audit log.

A clean test moved Michael Carter (`mcarter`) from IT to Sales, including `IT_Admin` → `Sales_Users`, the Sales OU, and the Sales Systems Specialist title.

![Mover success](Phase-2-PowerShell-Automation/Screenshots/Mover-Success.png)

![Mover verification](Phase-2-PowerShell-Automation/Screenshots/Mover-Verification.png)

![Mover audit log](Phase-2-PowerShell-Automation/Screenshots/Mover-Log.png)

### Leaver Workflow

`UserOffboarding.ps1` verifies the account exists, skips already-disabled users, captures existing access, resolves and validates the `Disabled_Users` OU before making changes, disables the account, removes non-default security groups, retains `Domain Users`, moves the account to `Disabled_Users`, and records SUCCESS/ERROR results.

A clean test offboarded Gavin Long (`glong`). The account was disabled, moved to `Disabled_Users`, and removed from both `IT_Admin` and `Gaming_Admin`. The audit log preserved those previous memberships before removal.

![Offboarding success](Phase-2-PowerShell-Automation/Screenshots/Offboarding-Success.png)

![Offboarding verification](Phase-2-PowerShell-Automation/Screenshots/Offboarding-Verification.png)

## Troubleshooting and Safety Improvements

Testing exposed realistic failure conditions that were used to harden the workflows:

- A Mover group-name mismatch produced a partial change and led to stronger `try/catch` handling and `-ErrorAction Stop`.
- An early Leaver test disabled an account and removed access before an OU-path problem stopped the final move.
- The failed Leaver attempt was preserved as an ERROR audit record, manually remediated, and separately recorded as `SUCCESS-MANUAL-REPAIR`.
- The Leaver workflow was then improved to validate the destination OU before destructive changes begin.
- A second Leaver test completed cleanly end-to-end with SUCCESS status.

These tests reinforced the importance of validation, audit trails, error handling, and recovery procedures in identity lifecycle management.

## Repository Layout

```text
Active-Directory-IAM-Lab/
├── README.md
├── .gitignore
├── GITHUB-UPLOAD-CHECKLIST.md
├── Phase-1-AD-Infrastructure/
│   └── Screenshots/
│       └── AD-Structure.png
├── Phase-2-PowerShell-Automation/
│   ├── UserProvisioning.ps1
│   ├── UserMover.ps1
│   ├── UserOffboarding.ps1
│   ├── NewEmployees-Sample.csv
│   ├── EmployeeChanges-Sample.csv
│   ├── EmployeeOffboarding-Sample.csv
│   ├── Logs/
│   │   ├── MoverLog-Sample.csv
│   │   └── OffboardingLog-Sample.csv
│   └── Screenshots/
│       ├── Provisioning-Script-1.png
│       ├── Provisioning-Script-2.png
│       ├── Provisioning-Results.png
│       ├── Group-Membership.png
│       ├── Mover-Success.png
│       ├── Mover-Verification.png
│       ├── Mover-Log.png
│       ├── Offboarding-Success.png
│       └── Offboarding-Verification.png
└── Phase-3-RBAC-Least-Privilege/
    ├── README.md
    └── Screenshots/
        ├── HR-NTFS-Permissions.png
        ├── HR-Network-Share.png
        ├── HR-Access-Granted-Modify.png
        ├── HR-Access-Denied.png
        ├── Mover-Sales-to-HR.png
        ├── Mover-HR-Membership-Verification.png
        └── Mover-RBAC-Access-Granted.png
```

## Running the Scripts

These scripts are intended for a controlled Active Directory lab. Review all domain names, OU mappings, group names, CSV paths, and logging paths before running them in another environment.

## Phase 3 — RBAC / Least Privilege

Implemented group-based resource authorization using Active Directory security groups, Windows file sharing, and NTFS permissions.

The authorization model follows:

```text
User -> Department Security Group -> Resource Permission
```

An HR resource was created at `C:\CompanyShares\HR` and shared as `\\Lab\hr`.

- Removed broad `Users` access from the HR folder.
- Assigned `HR_Users` Modify permission at the NTFS level.
- Removed `Everyone` from the share permissions.
- Assigned `HR_Users` Change + Read share permissions.
- Retained administrative and SYSTEM access.
- Verified an HR user could read and create files in the protected resource.
- Verified a non-HR user authenticated successfully but received `Access is denied` when attempting to access the HR resource.

### RBAC Authorization Testing

**HR NTFS permissions assigned through the `HR_Users` security group:**

![HR NTFS Permissions](Phase-3-RBAC-Least-Privilege/Screenshots/HR-NTFS-Permissions.png)

**Unauthorized access test — Sales user authenticated successfully but was denied access to the HR resource:**

![HR Access Denied](Phase-3-RBAC-Least-Privilege/Screenshots/HR-Access-Denied.png)

### JML and RBAC Integration

The existing Mover workflow was integrated with the RBAC model to demonstrate how a business-role change affects resource authorization.

Michael Carter (`mcarter`) initially belonged to `Sales_Users` and was denied access to the HR resource. `UserMover.ps1` was then used to transfer the account from Sales to HR.

The workflow:

- Updated the department from Sales to HR.
- Updated the job title to HR Systems Specialist.
- Moved the account from the Sales OU to the HR OU.
- Removed `Sales_Users`.
- Added `HR_Users`.

After the identity change, the same account successfully accessed `\\Lab\hr` without assigning permissions directly to the user.

### Mover-to-RBAC Verification

**Mover verification — Michael's account was transferred to HR and `HR_Users` membership replaced his previous Sales access:**

![Mover HR Membership Verification](Phase-3-RBAC-Least-Privilege/Screenshots/Mover-HR-Membership-Verification.png)

**Access after the role change — the same account successfully accessed the HR resource through its new `HR_Users` membership:**

![Mover RBAC Access Granted](Phase-3-RBAC-Least-Privilege/Screenshots/Mover-RBAC-Access-Granted.png)

```text
Business Role Change
        ↓
JML Mover Automation
        ↓
AD Security Group Membership
        ↓
RBAC Authorization
        ↓
Resource Access
```
Supporting evidence is documented in `Phase-3-RBAC-Least-Privilege`.

## Next Phase — Privileged Account Separation / Administrative Least Privilege

The next phase will focus on separating standard user identities from administrative identities and applying least privilege to privileged Active Directory administration.


## Security Note

All employee data in this repository is fictional. No passwords or credentials are stored in the project. Do not upload VM disks, snapshots, ISOs, exported appliances, private keys, or real employee information.
