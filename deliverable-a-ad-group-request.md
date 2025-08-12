# Request an Active Directory Group for Azure RBAC Assignment

## Purpose
This process outlines the required information and approval flow for requesting a new **on-premises Active Directory (AD)** group, synchronized to Microsoft Entra ID, for use in Azure Role-Based Access Control (RBAC) assignments.  
The goal is to ensure all groups are created in compliance with governance standards, follow naming conventions, and are properly documented in SailPoint for lifecycle management.

## Page Metadata
- **Owner:** IAM Operations Team
- **Review Cycle:** Quarterly
- **Last Updated:** [Date]
- **Related Roles:** Azure Owner, User Access Administrator

## Prerequisites
- Access to the SailPoint IdentityIQ request portal.
- Proposed group is for Azure access control (management group, subscription, resource group, or resource).
- Group will be synchronized to Microsoft Entra ID and appear as a security group in Azure.

## Process Steps

### Step 1 – Submit Group Request in SailPoint
1. Navigate to the **SailPoint IdentityIQ** request portal.
2. Select **"Request New AD Security Group"**.
3. Complete all required fields:
   - **Proposed Group Name** – Follow `[Your Naming Convention Placeholder]`.
   - **Description** – Include target Azure scope.
   - **Owner(s)** – One or more responsible business owners.
   - **Intended Role(s)** – List Azure RBAC role(s) this group will be assigned to.
   - **Scope** – Management Group, Subscription, Resource Group, or Resource.
   - **Business Justification** – Why this group is required.
   - **SoD/Risk Notes** – Identify potential segregation-of-duties conflicts.
   - **Cost Center / Department**
   - **Data Classification**
4. Attach supporting documentation if required.

![Example SailPoint group request form](link-to-screenshot-S1)

### Step 2 – Approval Workflow
- **Manager Approval** – Confirms business need and ownership.
- **IAM Team Review** – Confirms compliance with naming, scope, and least-privilege principles.
- **Security Review** – (If applicable) for high-risk or privileged access groups.
- **Final Creation in AD** – Performed by the IAM/Directory Services team.

### Step 3 – Group Creation & Synchronization
- Group is created in **on-premises Active Directory** in the appropriate OU.
- Group synchronization to **Microsoft Entra ID** occurs via **Entra Connect** within ~30 minutes.
- Group object is visible in Azure under **Microsoft Entra ID → Groups**.

![Synced group in Entra ID](link-to-screenshot-S2)

### Step 4 – Post-Creation Tasks
- Record the group in **SailPoint** with correct owner, description, and lifecycle policy.
- Schedule **Access Reviews** – Quarterly or per compliance requirements.
- Add to the **Azure RBAC Assignment** request queue.

## Related Documents
- [How to Build a Custom Role in Azure (Portal)](link-placeholder)
- [How to Assign an AD Group to an Azure Role](link-placeholder)
- [IAM Naming Convention – Groups & Roles](link-placeholder)
