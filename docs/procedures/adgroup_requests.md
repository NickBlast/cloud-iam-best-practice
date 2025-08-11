
# Request an Active Directory Group for Azure RBAC Assignment

```wiki
{toc:minLevel=1|maxLevel=3|style=disc|outline=false}
```

---

```wiki
{panel:title=Purpose|borderStyle=solid|borderColor=#ccc|bgColor=#F4F5F7}
This process outlines the required information and approval flow for requesting a new **on-premises Active Directory (AD)** group, synchronized to Microsoft Entra ID, for use in Azure Role-Based Access Control (RBAC) assignments. 
The goal is to ensure all groups are created in compliance with governance standards, follow naming conventions, and are properly documented in SailPoint for lifecycle management.
{panel}
```

---

```wiki
{panel:title=Page Metadata|borderStyle=solid|borderColor=#ccc|bgColor=#F4F5F7}
|| Owner || [IAM Operations Team] ||
|| Review Cycle || Quarterly ||
|| Last Updated || @currentDate ||
|| Related Roles || Azure Owner, User Access Administrator ||
{panel}
```

---

## Prerequisites

```wiki
{status:colour=Green|title=IAM Portal Access|subtle=true}
{status:colour=Green|title=SailPoint Account|subtle=true}
{status:colour=Yellow|title=Confirmed Naming Standard|subtle=true}
```

* **Requestor** has access to the SailPoint IdentityIQ request portal.
* **Proposed group** is for Azure access control.
* Group will be synchronized to Microsoft Entra ID and appear as a security group in Azure.

---

## Request Steps

### 1. Submit Group Request in SailPoint

```wiki
{tasklist}
- Navigate to the **SailPoint IdentityIQ** request portal.
- Select **"Request New AD Security Group"**.
- Complete all required fields in the request form.
- Attach supporting documentation (compliance ticket, approval email, etc.).
{tasklist}
```

**Required fields:**

* **Proposed Group Name** – Follow `[Your Naming Convention Placeholder]`.
* **Description** – Include target Azure scope.
* **Owner(s)** – Business owners.
* **Intended Role(s)** – Azure RBAC role(s).
* **Scope** – Management Group, Subscription, RG, or Resource.
* **Business Justification** – Why this group is required.
* **SoD/Risk Notes** – Potential conflicts.
* **Cost Center / Department**
* **Data Classification** – Sensitive or regulated?

![Example SailPoint group request form|thumbnail](link-to-screenshot-S1)

---

```wiki
{expand:title=More Info on SoD/Risk Notes}
Segregation of Duties checks ensure that no individual has excessive conflicting access which may lead to risk. Consult the IAM policy for restricted role combinations.
{expand}
```

---

### 2. Approval Workflow

```wiki
{info:title=Approval Flow}
- **Manager Approval** – Confirms business need.
- **IAM Team Review** – Naming, scope, and least-privilege check.
- **Security Review** – For high-risk or privileged groups.
- **Final Creation in AD** – IAM/Directory Services team.
{info}
```

---

### 3. Group Creation & Synchronization

* Created in **on-premises AD** in the correct OU.
* Synced to **Microsoft Entra ID** via Entra Connect (\~30 min cycle).
* Visible in Azure under **Microsoft Entra ID → Groups**.

![Synced group in Entra ID|thumbnail](link-to-screenshot-S2)

---

### 4. Post-Creation Tasks

```wiki
{warning:title=Post-Creation Governance}
Failure to complete these may result in access review findings or removal.
{warning}
```

* Record the group in **SailPoint** with correct owner and lifecycle policy.
* Schedule **Access Reviews** – Quarterly or per compliance requirements.
* Add to **Azure RBAC Assignment** request queue.

---

## Related Documents

```wiki
[How to Build a Custom Role in Azure (Portal)|link-placeholder]
[How to Assign an AD Group to an Azure Role|link-placeholder]
[IAM Naming Convention – Groups & Roles|link-placeholder]
```

---

```wiki
{attachments:patterns=.*\.(png|jpg|jpeg|pdf)|upload=true}
```
