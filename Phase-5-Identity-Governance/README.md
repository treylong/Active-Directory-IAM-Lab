# Phase 5 — Identity Governance & Access Reviews

## Objective

This phase extends the Active Directory IAM lab from access control into identity governance. The goal was to identify accounts that require human review, evaluate whether existing access is still justified, remediate unnecessary access, and verify the resulting state.

The phase follows a review-first model:

```text
Identity inventory
      |
      v
Inactivity / access review criteria
      |
      v
Human review decision
      |
      v
Targeted remediation
      |
      v
Post-remediation verification
```

## Identity Access Review

A PowerShell review workflow was built to inspect enabled Active Directory accounts, activity-related attributes, and group memberships. The review logic classifies accounts with role-based group access as `REVIEW` while identities with only the default `Domain Users` membership are treated as `LOW ACCESS` for the lab scenario.

The review does not automatically remove access. A `REVIEW` result indicates that the identity requires human validation before any change is made.

The reusable reporting script is included as [`IdentityAccessReview.ps1`](IdentityAccessReview.ps1).

## Access Review Finding

The account `elong` was selected as the controlled access-review case. During investigation, the identity was enabled but had no populated department or title and retained both HR and Management group memberships:

```text
Domain Users
HR_Users
Managers
```

This combination was treated as a lab governance finding because the assigned access could not be justified by the identity attributes being reviewed.

![Access Review Before Remediation](Screenshots/Access-Review-Before-Remediation.png)

## Access Remediation

The review decision was to remove the unnecessary `HR_Users` and `Managers` memberships while preserving the default `Domain Users` membership.

After remediation, verification showed:

```text
Domain Users
```

The refreshed access-review logic then classified `elong` as `LOW ACCESS`.

![Access Review After Remediation](Screenshots/Access-Review-After-Remediation.png)

Sample before- and after-remediation CSV evidence is included in:

- [`AccessReview-Sample.csv`](AccessReview-Sample.csv)
- [`AccessReview-PostRemediation-Sample.csv`](AccessReview-PostRemediation-Sample.csv)

## Inactive Account Review Policy

A 60-day inactivity threshold was defined for the lab. The logic was refined to avoid treating newly created accounts with no logon history as automatically stale.

An enabled account is considered a review candidate when either:

```text
A recorded LastLogonDate is older than 60 days
```

or:

```text
LastLogonDate is blank AND the account itself is older than 60 days
```

A review result is not an automatic disable action. It requires investigation and a documented remediation decision.

## Simulated Stale-Account Scenario

Because the home lab did not naturally contain an enabled identity with more than 60 days of inactivity, a dedicated fictional account named `staleuser` was created for a controlled simulation.

The simulation did **not** change the server clock or falsify Active Directory timestamps. Instead, PowerShell evaluated the account as though the review were occurring 61 days later.

The test account represented a Sales identity with:

```text
Department: Sales
OU: Sales
Groups: Domain Users, Sales_Users
Enabled: True
LastLogonDate: blank
```

The governance logic returned:

```text
REVIEW: staleuser meets the simulated 60-day inactivity threshold.
```

![Stale Account Detected](Screenshots/Stale-Account-Detected.png)

## Stale-Account Remediation

The simulated review decision was that the identity no longer required access. Remediation was performed in controlled stages:

1. Remove `Sales_Users` membership.
2. Verify that only `Domain Users` remained.
3. Disable the account.
4. Move the account to the `Disabled_Users` OU.
5. Verify account status, OU location, and group membership.

Before remediation, the account was enabled in the Sales OU and retained Sales access.

![Stale Account Before Remediation](Screenshots/Stale-Account-Before-Remediation.png)

Final verification showed:

```text
Enabled: False
OU: Disabled_Users
Groups: Domain Users only
```

![Stale Account Remediation Verified](Screenshots/Stale-Account-Remediation-Verified.png)

## Reusable Governance Reporting Script

The final PowerShell script performs a read-only Active Directory review and exports the current findings to:

```text
C:\AD-Lab\Phase5\IdentityAccessReview.csv
```

The portfolio copy also creates a header-only CSV when no current findings exist, so a clean post-remediation scan still produces a usable report artifact.

![Identity Access Review Script](Screenshots/Identity-Access-Review-Script.png)

## Security Concepts Demonstrated

- Identity governance
- Periodic access review
- Inactive/stale-account identification
- Review-before-remediation workflow
- Group-membership analysis
- Least-privilege remediation
- Disabled-account containment
- Before/after evidence collection
- PowerShell reporting and CSV export
- Separation of detection from enforcement

## Outcome

This phase demonstrates a practical identity-governance workflow rather than automatic access revocation. Active Directory identities are evaluated using activity and authorization data, suspicious access is reviewed before changes are made, remediation is targeted and verified, and the final state is documented through reusable PowerShell reporting and before/after evidence.

> **Lab note:** All identities and data are fictional and used only in an isolated home lab. The stale-account case is explicitly documented as a simulation. Production identity-governance programs should use approved inactivity thresholds, authoritative HR or identity sources, exception handling, ownership/attestation workflows, change controls, and centralized audit logging.
