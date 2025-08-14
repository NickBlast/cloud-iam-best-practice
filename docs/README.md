# 📊 IAM Research Initiative – Multi-Cloud Financial Institution

This repository documents a deep research initiative to evaluate and evolve IAM strategy for a hybrid multi-cloud environment (AWS, Azure/Entra, GCP) in a highly regulated financial enterprise.

---

## 📥 Research Objective

To identify best practices, tooling, staffing patterns, and emerging trends in Identity & Access Management as applied to **banking and financial services**, aligned with **FFIEC CAT**, **NIST 800-53**, and **CSA STAR** controls.

---

## 📌 Scope

### Cloud Platforms:
- AWS (multi-account, Terraform-managed, Ping federation)
- Azure/Entra (manual IAM with IaC roadmap, Okta federation)
- GCP (single project, AD group access, Terraform-defined)

### IAM Tooling:
- SailPoint IdentityIQ (group governance, access reviews)
- Ping Identity & Okta (federation, MFA)
- CyberArk & AWS Secrets Manager (manual secrets lifecycle)
- Splunk Cloud (log aggregation)
- Veza (planned posture observability)

---

## 🔍 Research Areas

1. **Best Practice IAM Design for Multi-Cloud Financial Environments**
2. **Tooling Evaluation**
3. **Team Design & Staffing Strategy**
4. **IAM Engineer Day-to-Day Responsibilities**
5. **Emerging Technologies & Sector Trends**
6. **Build vs Buy: Reporting, Drift Detection, IAM Metrics**
7. **IAM Engineers in a DevSecOps Model**

---

## 📊 Live Tracker

See [`IAM Research Tracking Sheet`](./IAM_Research_Tracking_Sheet.xlsx) for:
- Findings
- Recommended actions
- Tool mentions
- Financial-sector relevance
- Status tracking

---

## 📎 Outputs

All deep research results will be linked here by section, along with documented takeaways and decisions.

---

## 🧩 Related Documentation

- [`IAM Architecture Index`](./IAM_Architecture_Index.md)
- [`IAM Strategy Sections 1–10`](./architecture-docs/)
- [Splunk Dashboards (internal)](#)
- [Terraform IAM Modules (GitLab)](#)

---

## 📅 Review Cadence

- Updates reviewed weekly by IAM leadership
- Strategy iterations logged quarterly
- All findings tagged by relevance: `Compliance`, `Automation`, `Tooling`, `DevSecOps`, `JIT`, `Secrets`, `Governance`

