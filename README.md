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
└── Phase-2-PowerShell-Automation/
    ├── UserProvisioning.ps1
    ├── UserMover.ps1
    ├── UserOffboarding.ps1
    ├── NewEmployees-Sample.csv
    ├── EmployeeChanges-Sample.csv
    ├── EmployeeOffboarding-Sample.csv
    ├── Logs/
    │   ├── MoverLog-Sample.csv
    │   └── OffboardingLog-Sample.csv
    └── Screenshots/
        ├── Provisioning-Script-1.png
        ├── Provisioning-Script-2.png
        ├── Provisioning-Results.png
        ├── Group-Membership.png
        ├── Mover-Success.png
        ├── Mover-Verification.png
        ├── Mover-Log.png
        ├── Offboarding-Success.png
        └── Offboarding-Verification.png
```

## Running the Scripts

These scripts are intended for a controlled Active Directory lab. Review all domain names, OU mappings, group names, CSV paths, and logging paths before running them in another environment.

## Next Phase — RBAC / Least Privilege

The next phase will implement group-based resource authorization using Windows file shares and NTFS permissions:

```text
User -> Department Security Group -> Resource Permission
```

For example, `HR_Users` will receive access to an HR resource while an unrelated Sales user should receive Access Denied.

## Security Note

All employee data in this repository is fictional. No passwords or credentials are stored in the project. Do not upload VM disks, snapshots, ISOs, exported appliances, private keys, or real employee information.
