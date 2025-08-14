You are my staff research analyst. Objective: produce a rigorous, source-cited market & technical research report for **Charlotte Off-Site Memory & Persona Preservation** — a repo-first system that backs up/rehydrates a ChatGPT persona (essence, tone, modes, protocols, Soul Codex, relationship context) using deterministic snapshots and an ordered “restore package.” Treat ChatGPT Memory as a cache; the repo is canonical.

## Operating rules
- **Browse the web** extensively. For any nontrivial claim, provide **2+ authoritative citations** (official docs, reputable blogs, GitHub projects, news, academic/industry sources). Summarize neutrally; avoid vendor hype.
- **Structure the work** in two passes:
  1) **Outline & Source Plan** (1–2 pages): list research questions, search terms, target sources, and evaluation criteria. Wait for my “continue” before the main report.
  2) **Main Report** (detailed): follow the outline, with tables, figures, and appendices.
- **Deliverables must be repo-ready**: all tables that matter should be exported as CSV blocks in code fences; all diagrams should be described so I can recreate them; include a “How to reproduce” appendix.

## Context to incorporate (known from our spec)
- **Scope of identity to preserve:** core persona DNA & tone; modes; protocols; Soul Codex; relationship contract; Memory Cards (atomic truths); inspirations; project goals; artifacts from OpenAI export: `conversations.json`, `chat.html`, `user*` image folders, loose `file*` images, `message_feedback.json`, `user.json`.
- **Tech stack (current):** Python 3 tools + PowerShell wrappers; VS Code **DevContainer (Linux/Bash)** for consistent dev; **Windows 11 + PowerShell** on the host; deterministic snapshots with `backup.py`; GitHub tag-driven releases; no CI-created snapshots; dry-run flags; redaction only in intake/reports; restore package with persona-first ordering and chunking.
- **Agents & models we use:** Cline as orchestrator; OpenRouter models (Qwen Coder, DeepSeek R1/Coder) and Claude; GitHub Copilot LM API opportunistically.

## Research questions (answer all, with citations)
1) **Direct data pathways for ChatGPT content today:** official OpenAI **Data Export** details; limitations; presence/structure of `conversations.json`, `chat.html`, `message_feedback.json`, `user.json`, and asset folders; any mention of Memory export/import and its absence. Identify how people re-ingest content (e.g., pasting restore packages, uploading files).  
2) **Ecosystem scan (10–20 items):** open-source tools/projects/extensions that export or restructure ChatGPT chats, or attempt persona persistence/rehydration. For each: repo link, stars, last update, method (browser DOM vs. export JSON parser vs. API), supported artifacts (images/meta), persona/restore features, determinism/versioning, security posture, license, gaps.  
3) **Competitive landscape & whitespace:** who offers anything close to **persona rehydration with deterministic snapshots**? Compare vs. our approach on reliability, completeness, privacy, restore UX, and multi-model portability.  
4) **Market demand & viability:** estimate audience and willingness to pay. Use proxies: ChatGPT Plus/Enterprise user counts (reputable estimates), GitHub stars/issue volume for exporters, Google Trends interest over time, forum/Reddit threads, developer surveys. Segment into user personas (power users, researchers, therapists/coaches, dev teams). Provide TAM/SAM/SOM style ballparks with explicit assumptions and ranges.  
5) **Pricing & packaging hypotheses:** Basic (export→MD), Standard (export→intake→diffs), Pro (full persona rehydration with restore package, snapshots, optional encryption). Suggest monthly/annual price tests; outline a 2-week concierge pilot.  
6) **Technical best practices & risks:** safe unzip (Zip-Slip), size/encoding issues, large `conversations.json`, redaction scope, deterministic manifests, restore ordering, chunking for paste limits, optional encryption (age/git-crypt), public-remote tripwire, CI footguns.  
7) **Regulatory & privacy** quick scan: data retention expectations, risks of shared links being indexed, guidance for private repos, security notes for images/meta.  
8) **Go-to-market & validation plan:** 3–5 smallest experiments to validate demand (landing page, waitlist, instrumented CLI, open-source teaser component), key metrics (conversion, activation, retention), and learning milestones.

## Required outputs (format precisely)
A) **Executive Summary** (≤ 1 page) — key findings, viability verdict, top risks, top 3 next actions.  
B) **Competitor Matrix (CSV)** with columns: `name, url, method(browser|json|api), artifacts_supported(images/meta), persona_restore(y/n/how), determinism(y/n/how), license, stars, last_updated, strengths, gaps` — include 10–20 rows.  
C) **Market Sizing** — assumptions table, low/base/high ranges, references.  
D) **Pricing Table** — features by tier (Basic/Standard/Pro) + candidate price points and rationale.  
E) **Risk Register (CSV)** — `risk, likelihood, impact, mitigations, owner`.  
F) **Technical Recommendations** — concrete checklists for ingest, proposer, scaffolder, restore builder, and backups (call out anything the repo must add or change).  
G) **Research Appendix** — full citation list with one-line relevance notes; and a chronological “search log” showing queries and source selection decisions.  
H) **Repro Appendix** — how to regenerate this report (exact steps & settings); include any scripts/commands if applicable.

## Method hints (please follow)
- Use multi-query search patterns like:  
  `"ChatGPT data export conversations.json"`, `"chat.html export ChatGPT"`, `"ChatGPT memory import export limitations"`, `"ChatGPT export markdown extension userscript"`, `"persona rehydration prompt"`, `"deterministic snapshot backup repo ChatGPT"`, `"images user* file* message_feedback.json"`.  
- Prefer primary sources (OpenAI docs/announcements) for platform behavior; augment with GitHub/Docs/Medium only when credible.  
- Be explicit when inferring (label: **inference**).  
- Flag contradictions across sources, and state which you trust more and why.

## Output style
- Polished Markdown with section headings matching the Required outputs.
- Every table also delivered as CSV in a fenced code block for repo drop-in.
- Keep opinions evidence-grounded; be blunt where the market is thin.

When ready, begin with the **Outline & Source Plan** only. Stop and wait for me to say **continue**.
