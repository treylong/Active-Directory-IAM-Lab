# Phase 3 — RBAC / Least Privilege

This phase demonstrates group-based resource authorization in the `lab.local` Active Directory home lab.

## RBAC Model

`User -> Department Security Group -> Resource Permission`

The HR resource was configured at `C:\CompanyShares\HR` and shared as `\\Lab\hr`.

- Broad `Users` access was removed from the HR folder.
- `HR_Users` received **Modify** NTFS permission.
- `Everyone` was removed from the share permissions.
- `HR_Users` received **Change + Read** share permissions.
- Administrative and SYSTEM access was retained.

## Authorization Testing

### Positive test — HR user

Sarah Jones (`sjones`), a member of `HR_Users`, successfully connected to `\\Lab\hr`, listed the protected files, and created `Sarah-RBAC-Test.txt`. This verified that the HR role had the expected read/write/modify access.

### Negative test — non-HR user

Michael Carter (`mcarter`) was a member of `Sales_Users` and not `HR_Users`. His credentials authenticated successfully to the server, but `dir \\Lab\hr` returned **Access is denied**. This demonstrates the distinction between authentication and authorization.

## JML + RBAC Integration

The existing `UserMover.ps1` workflow was then used to simulate Michael transferring from Sales to HR.

The Mover workflow:
- changed Department from Sales to HR;
- changed the job title to HR Systems Specialist;
- moved the account to the HR OU;
- removed `Sales_Users`;
- added `HR_Users`.

After the move, the same `mcarter` account successfully accessed `\\Lab\hr`. No direct permission was assigned to Michael; access changed through his new security-group membership.

This demonstrates an end-to-end IAM lifecycle:

`Business role change -> JML Mover -> AD group membership -> RBAC authorization -> Resource access`

## Evidence

See the `Screenshots` folder for NTFS configuration, network sharing, Access Granted/Denied testing, and Mover-to-RBAC verification.
