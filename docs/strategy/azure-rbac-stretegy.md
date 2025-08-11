# Simplified Azure RBAC Strategy for Team-Based Access via AD Groups

## Objective

Design an auditable and efficient RBAC model in Azure that leverages SailPoint-managed AD groups, reduces group sprawl, simplifies certification, and aligns with audit expectations—all without relying on nested Azure AD groups or advanced CIEM tooling (until future implementation).

## Current Constraints

1. Users are provisioned to AD groups via SailPoint.
2. All AD groups must be certifiable, with clear ownership and revocation controls.
3. Azure RBAC assignments are managed manually via the Azure Portal.
4. Group-level assignments and access must be visible during certification reviews.

## Proposed Model

### Group Assignment Structure

Instead of the legacy nested model:
- User → SailPoint → Team AD Group
- Team AD Group → Azure AD Group
- Azure AD Group → Azure Role Assignment

Use a simplified direct model:

### Naming Convention

Use consistent, purpose-driven naming for team role groups: role-azure-<teamname>

### Azure Role Assignment
 
Assign team AD groups **directly** to Azure RBAC roles at the appropriate scope level (Management Group, Subscription, Resource Group, etc.) to eliminate inheritance ambiguity and enhance audit clarity.

## Benefits

| Benefit | Description |
|--------|-------------|
| **Eliminates nesting risk** | Direct group → role assignment ensures consistent access control behavior across all Azure services. |
| **Audit-friendly** | Certifications focus on team-level group membership with clear visibility into resulting access. |
| **Minimizes group sprawl** | Reuses team groups for all Azure scopes rather than creating duplicate role-specific groups per team. |
| **Simplifies ownership** | Group owners certify access once per group rather than across multiple duplicative groups. |

## Limitations

| Limitation | Mitigation |
|------------|------------|
| Less reusable role logic across teams | Maintain a catalog of scopes and roles tied to each group for visibility and governance. |
| No nested group flexibility | Offset by clearer governance and reduced risk. |
| Audit prefers linear user-to-access paths | Provide exportable reports mapping: `User → Group → Role @ Scope`. |

## Governance Recommendations

1. **Group Scoping Discipline**  
   Ensure team groups (`role-azure-<teamname>`) are only used for Azure access—avoid multifunction usage.

2. **Certification Support**  
   During SailPoint certification campaigns, provide documentation showing each team group’s assigned Azure roles and scopes.

3. **Access Mapping Inventory**  
   Maintain an internal mapping document or dashboard that tracks:
   - Group → Azure scope(s)
   - Group → Azure role(s)
   - Group → Membership (users)

4. **PowerShell/Graph Reporting**  
   Create scheduled reports to generate:
   - All team groups with their Azure role assignments
   - User membership per group
   - Effective access by user (User → Group → Role @ Scope)

5. **Audit Documentation**  
   Develop lightweight internal documentation outlining:
   - Naming conventions
   - Access design patterns
   - Role assignment workflows
   - Group ownership and certification responsibilities

## Future Considerations (CIEM Integration)

When SailPoint CIEM functionality is available:

- Directly certify access at the Azure resource/role level.
- Ingest role assignments, scopes, and entitlements directly into SailPoint.
- Further reduce manual access mapping and reporting overhead.

## Summary

This proposed structure removes reliance on Azure AD nesting while maintaining scalability, auditability, and SailPoint governance. By assigning team-level AD groups directly to Azure roles and scopes, we enable:

- Clean certification paths
- Minimal group overhead
- Regulator-aligned user-to-access reporting
- Simpler future transition into CIEM or more advanced entitlement management platforms
