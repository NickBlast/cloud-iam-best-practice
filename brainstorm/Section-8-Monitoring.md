# 🧠 IAM Architecture Brain Dump  
## Section 8 – Auditing & Monitoring

---

### 📦 Log Aggregation & Visibility

| Platform | Log Source                         | Centralized In? | Notes                                               |
|----------|-------------------------------------|------------------|-----------------------------------------------------|
| **AWS**  | CloudTrail, CloudWatch, IAM events | ✅ Splunk Cloud   | Includes role assumptions, STS activity, key usage  |
| **Azure**| Entra ID Logs, Azure Activity Logs | ✅ Splunk Cloud   | Includes sign-in events, directory changes          |
| **GCP**  | Audit Logs, IAM activity logs       | ✅ Splunk Cloud   | Logs role bindings, service account usage           |

- **Splunk Cloud** serves as the **central log aggregation and search platform**
- Used for:
  - IAM access traceability
  - Historical analysis
  - Ad hoc audit response
- **IAM-specific dashboards** are planned but not yet standardized

---

### 🔔 Alerting & Monitoring Use Cases

- **Privileged Role Assumption**
  - Alerts on STS usage in AWS (role assumption)
  - Manual reviews for Azure and GCP privileged role assignments
- **Secrets Usage or Access Key Events**
  - AWS Secrets Manager logs usage; monitored via Splunk
  - CyberArk lacks native event integration—manual logging only
- **Group Membership Changes**
  - SailPoint may emit provisioning logs to Splunk
  - No direct alerting yet on "high-risk" group changes

---

### 🔍 Drift Detection & Reconciliation

| Area         | Detection Method       | Notes                                                     |
|--------------|------------------------|-----------------------------------------------------------|
| **AWS IAM**  | Terraform + PR review  | Manual validation during PR; no continuous detection       |
| **Azure IAM**| No tooling yet         | Role assignments managed manually—no drift alerts         |
| **GCP IAM**  | Terraform only         | Drift may occur with direct changes outside IaC           |

- No real-time detection of IAM policy drift across platforms
- Opportunity to integrate **policy diff tools** (e.g., Terraform plan diff + approval gates)
- **Veza onboarding** may support IAM visibility and drift reconciliation

---

### 🔐 Access Review Monitoring

- **Access Certifications**:
  - Driven via **SailPoint** review workflows (user/group)
  - Manual campaign requests submitted through **ServiceNow**
- **Privileged Access Reviews**:
  - Annual policy and role recertification
  - Results logged and auditable in Splunk or certification tools
- No continuous monitoring of low-usage or excessive-privilege accounts

---

### ⚠️ Known Gaps & Monitoring Limitations

| Gap Area                     | Description                                                                 |
|------------------------------|-----------------------------------------------------------------------------|
| **CyberArk audit integration** | No event stream for secrets access, no Splunk integration                  |
| **Privileged access visibility** | No real-time alerts on high-privilege usage in Azure or GCP                |
| **Drift detection**          | No continuous reconciliation between declared state (IaC) and deployed state |
| **MFA enforcement audit**    | MFA policy logs reside in IdPs (Ping/Okta), not cloud-native logging layers |
| **IAM event dashboards**     | Splunk ingestion exists, but IAM-specific dashboards are ad hoc or missing   |
