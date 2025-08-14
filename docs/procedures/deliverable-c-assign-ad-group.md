# Assign an AD Group to an Azure Role (Portal)

## Purpose
This process outlines how to assign a **synchronized on-premises Active Directory group** (visible in Microsoft Entra ID) to a built-in or custom Azure role at the correct scope (Management Group, Subscription, Resource Group, or Resource).  
The goal is to ensure role assignments follow least-privilege principles and are properly documented for audit and review.

## Page Metadata
- **Owner:** IAM Cloud Operations
- **Review Cycle:** Quarterly
- **Last Updated:** [Date]
- **Related Roles:** User Access Administrator, Owner

## Prerequisites
- The AD group must be created and synchronized to Microsoft Entra ID.
- You must have a role with `Microsoft.Authorization/roleAssignments/write` at the target scope.
- The scope for assignment must be determined in advance.

## Process Steps

### Step 1 – Navigate to the Target Scope
1. Sign in to the [Azure Portal](https://portal.azure.com).
2. Go to the **Management Group**, **Subscription**, **Resource Group**, or **Resource** where the role will be assigned.
3. Select **Access control (IAM)** from the left-hand menu.
4. Click **Add** → **Add role assignment**.

![Azure IAM blade](link-to-screenshot-C1)

### Step 2 – Select the Role
- Choose the **custom role** or **built-in role** that matches the access requirements.
- Use the built-in role descriptions or custom role JSON as references.

![Role selection screen](link-to-screenshot-C2)

### Step 3 – Assign to the AD Group
- **Member type**: Select **Group**.
- Search for the **synchronized AD group** by name.
- Select the group and click **Next**.

![Select group screen](link-to-screenshot-C3)

### Step 4 – Add Assignment Details
- Fill out the **Description/Justification** field if available.
- Confirm scope and role are correct.

![Assignment details screen](link-to-screenshot-C4)

### Step 5 – Review + Assign
- Click **Review + assign** to finalize the role binding.
- Wait for Azure to confirm the role assignment.

![Review and assign screen](link-to-screenshot-C5)

## Post-Process Tasks
- Record the role assignment details (Scope, Role, Principal Object ID) in the **Access Control Register**.
- Update the related documentation.
- Add the group to the **Quarterly Access Review** list.

## Related Documents
- [How to Request an AD Group for Azure RBAC Assignment](link-placeholder)
- [How to Create a Custom Role in Azure (Portal)](link-placeholder)
- [Azure Role Assignments Documentation](https://learn.microsoft.com/azure/role-based-access-control/role-assignments-portal)
