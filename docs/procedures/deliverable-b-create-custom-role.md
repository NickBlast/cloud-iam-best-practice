# Create a Custom Role in Azure (Portal)

## Purpose
This process describes how to create a **custom Azure RBAC role** through the Azure portal at the required scope (Management Group, Subscription, or Resource Group).  
The objective is to define roles with least privilege, in alignment with our governance and naming standards, and capture configuration details for later Infrastructure-as-Code (Terraform) implementation.

## Page Metadata
- **Owner:** IAM Cloud Team
- **Review Cycle:** Quarterly
- **Last Updated:** [Date]
- **Related Roles:** User Access Administrator, Owner

## Prerequisites
- You must have **Owner**, **User Access Administrator**, or a custom role with `Microsoft.Authorization/roleDefinitions/write` at the intended scope.
- The target scope (Management Group, Subscription, or Resource Group) must be determined before starting.
- Naming standard confirmed ([placeholder link]).

## Process Steps

### Step 1 – Navigate to the Target Scope
1. Sign in to the [Azure Portal](https://portal.azure.com).
2. Go to the **Management Group**, **Subscription**, or **Resource Group** where the custom role will be created.
3. Select **Access control (IAM)** from the left-hand menu.
4. Click **Add** → **Add custom role**.

![Azure IAM blade](link-to-screenshot-B1)

### Step 2 – Configure the Role – Basics
- **Name**: Enter the role name following the naming convention.
- **Description**: Clearly describe the purpose.
- **Baseline permissions source**: Choose *Start from scratch* or *Clone a role*.

![Custom role basics screen](link-to-screenshot-B2)

### Step 3 – Configure Permissions
- Click **+ Add permissions**.
- Search for and select the relevant permissions for the role.
- Use **NotActions** or **NotDataActions** to explicitly exclude capabilities if starting from a broader baseline.

![Permissions selection screen](link-to-screenshot-B3)

### Step 4 – Assignable Scopes
- Add the scope(s) where this role will be visible for assignment.
- Best practice: define roles at **Management Group** for broad visibility, or **Subscription** if scope is contained.

![Assignable scopes screen](link-to-screenshot-B4)

### Step 5 – Review + Create
- Validate that no wildcard (`*`) permissions are present unless explicitly approved.
- Click **Review + create**.
- Upon creation, copy the generated role JSON for record keeping and future Terraform import.

![Role creation review screen](link-to-screenshot-B5)

## Post-Process Tasks
- Save role JSON to the **RBAC Configuration** repository.
- Update related documentation with role metadata.
- Add to quarterly access review list.

## Related Documents
- [How to Request an AD Group for Azure RBAC Assignment](link-placeholder)
- [How to Assign an AD Group to an Azure Role](link-placeholder)
- [Azure RBAC Custom Roles Documentation](https://learn.microsoft.com/azure/role-based-access-control/custom-roles-portal)
