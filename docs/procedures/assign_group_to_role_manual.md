# Assign an AD Group to an Azure Role (Portal)

```wiki
{toc:minLevel=1|maxLevel=3|style=disc|outline=false}
```

---

```wiki
{panel:title=Purpose|borderStyle=solid|borderColor=#ccc|bgColor=#F4F5F7}
This process outlines how to assign a **synchronized on-premises Active Directory group** (visible in Microsoft Entra ID) to a built-in or custom Azure role at the correct scope (Management Group, Subscription, Resource Group, or Resource).  
The goal is to ensure role assignments follow least-privilege principles and are properly documented for audit and review.
{panel}
```

---

```wiki
{panel:title=Page Metadata|borderStyle=solid|borderColor=#ccc|bgColor=#F4F5F7}
|| Owner || [IAM Cloud Operations] ||
|| Review Cycle || Quarterly ||
|| Last Updated || @currentDate ||
|| Related Roles || User Access Administrator, Owner ||
{panel}
```

---

## Prerequisites

```wiki
{status:colour=Green|title=Azure Portal Access|subtle=true}
{status:colour=Green|title=Role Assignment Permissions|subtle=true}
{status:colour=Yellow|title=Synced AD Group in Entra ID|subtle=true}
```

* The AD group must be created and synchronized to Microsoft Entra ID.
* You must have a role with `Microsoft.Authorization/roleAssignments/write` at the target scope.
* The scope for assignment must be determined in advance.

---

## Assignment Steps

### 1. Navigate to the Target Scope

```wiki
{tasklist}
- Sign in to the [Azure Portal|https://portal.azure.com].
- Go to the **Management Group**, **Subscription**, **Resource Group**, or **Resource** where the role will be assigned.
- Select **Access control (IAM)** from the left-hand menu.
- Click **Add** → **Add role assignment**.
{tasklist}
```

![Azure IAM blade|thumbnail](link-to-screenshot-C1)

---

### 2. Select the Role

* Choose the **custom role** or **built-in role** that matches the access requirements.
* Use the built-in role descriptions or custom role JSON as references.

![Role selection screen|thumbnail](link-to-screenshot-C2)

---

```wiki
{expand:title=Built-in Role Reference}
Refer to the [Azure built-in roles catalog|https://learn.microsoft.com/azure/role-based-access-control/built-in-roles] for detailed permissions.
{expand}
```

---

### 3. Assign to the AD Group

* **Member type**: Select **Group**.
* Search for the **synchronized AD group** by name.
* Select the group and click **Next**.

![Select group screen|thumbnail](link-to-screenshot-C3)

---

### 4. Add Assignment Details

```wiki
{info:title=Justification Requirement}
Include a business justification for the assignment. This supports access review and audit requirements.
{info}
```

* Fill out the **Description/Justification** field if available.
* Confirm scope and role are correct.

![Assignment details screen|thumbnail](link-to-screenshot-C4)

---

### 5. Review + Assign

```wiki
{warning:title=Inheritance Reminder}
Assignments at higher scopes (e.g., Management Group) inherit down to all child subscriptions and resources unless explicitly overridden.
{warning}
```

* Click **Review + assign** to finalize the role binding.
* Wait for Azure to confirm the role assignment.

![Review and assign screen|thumbnail](link-to-screenshot-C5)

---

## Post-Assignment Tasks

* Record the role assignment details (Scope, Role, Principal Object ID) in the **Access Control Register**.
* Update the related Confluence role page.
* Add the group to the **Quarterly Access Review** list.

---

## Related Documents

```wiki
[How to Request an AD Group for Azure RBAC Assignment|link-placeholder]
[How to Create a Custom Role in Azure (Portal)|link-placeholder]
[Azure Role Assignments Documentation|https://learn.microsoft.com/azure/role-based-access-control/role-assignments-portal]
```

---

```wiki
{attachments:patterns=.*\.(png|jpg|jpeg|pdf)|upload=true}
```