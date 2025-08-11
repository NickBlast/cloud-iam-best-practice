# Create a Custom Role in Azure (Portal)

```wiki
{toc:minLevel=1|maxLevel=3|style=disc|outline=false}
```

---

```wiki
{panel:title=Purpose|borderStyle=solid|borderColor=#ccc|bgColor=#F4F5F7}
This process describes how to create a **custom Azure RBAC role** through the Azure portal at the required scope (Management Group, Subscription, or Resource Group).  
The objective is to define roles with least privilege, in alignment with our governance and naming standards, and capture configuration details for later Infrastructure-as-Code (Terraform) implementation.
{panel}
```

---

```wiki
{panel:title=Page Metadata|borderStyle=solid|borderColor=#ccc|bgColor=#F4F5F7}
|| Owner || [IAM Cloud Team] ||
|| Review Cycle || Quarterly ||
|| Last Updated || @currentDate ||
|| Related Roles || User Access Administrator, Owner ||
{panel}
```

---

## Prerequisites

```wiki
{status:colour=Green|title=Azure Portal Access|subtle=true}
{status:colour=Green|title=Required RBAC Permissions|subtle=true}
{status:colour=Yellow|title=Confirmed Naming Standard|subtle=true}
```

* You must have **Owner**, **User Access Administrator**, or a custom role with `Microsoft.Authorization/roleDefinitions/write` at the intended scope.
* The target scope (Management Group, Subscription, or Resource Group) must be clear before starting.
* Naming standard confirmed (\[placeholder link]).

---

## Role Creation Steps

### 1. Navigate to the Target Scope

```wiki
{tasklist}
- Sign in to the [Azure Portal|https://portal.azure.com].
- Go to the **Management Group**, **Subscription**, or **Resource Group** where the custom role will be created.
- Select **Access control (IAM)** from the left-hand menu.
- Click **Add** → **Add custom role**.
{tasklist}
```

![Azure IAM blade|thumbnail](link-to-screenshot-B1)

---

### 2. Configure the Role – Basics

```wiki
{info:title=Naming Standard Reminder}
Use the approved naming convention placeholder: `[ROLEPREFIX]-[Service]-[ScopeSuffix]`.
{info}
```

* **Name**: Enter the role name following the naming convention.
* **Description**: Clearly describe the purpose.
* **Baseline permissions source**: Choose *Start from scratch* or *Clone a role*.

![Custom role basics screen|thumbnail](link-to-screenshot-B2)

---

### 3. Configure Permissions

```wiki
{expand:title=Understanding Actions vs. DataActions}
- **Actions** control management plane operations (e.g., creating resources).
- **DataActions** control data plane operations (e.g., reading data from storage).
Refer to the [Azure RBAC permissions model|https://learn.microsoft.com/azure/role-based-access-control/role-definitions].
{expand}
```

* Click **+ Add permissions**.
* Search for and select the relevant permissions for the role.
* Use **NotActions** or **NotDataActions** to explicitly exclude capabilities if starting from a broader baseline.

![Permissions selection screen|thumbnail](link-to-screenshot-B3)

---

### 4. Assignable Scopes

* Add the scope(s) where this role will be visible for assignment.
* Best practice: define roles at **Management Group** for broad visibility, or **Subscription** if scope is contained.

![Assignable scopes screen|thumbnail](link-to-screenshot-B4)

---

### 5. Review + Create

```wiki
{warning:title=Governance Check}
Avoid wildcard (`*`) permissions unless explicitly approved.  
Validate that all required SoD reviews have been completed before publishing.
{warning}
```

* Click **Review + create**.
* Upon creation, copy the generated role JSON for record keeping and future Terraform import.

![Role creation review screen|thumbnail](link-to-screenshot-B5)

---

## Post-Creation Tasks

* Save role JSON to the **RBAC Configuration** repository.
* Update related Confluence page(s) with role metadata.
* Add to quarterly access review list.

---

## Related Documents

```wiki
[How to Request an AD Group for Azure RBAC Assignment|link-placeholder]
[How to Assign an AD Group to an Azure Role|link-placeholder]
[Azure RBAC Custom Roles Documentation|https://learn.microsoft.com/azure/role-based-access-control/custom-roles-portal]
```

---

```wiki
{attachments:patterns=.*\.(png|jpg|jpeg|pdf)|upload=true}
```