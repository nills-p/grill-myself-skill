# Grill Myself: a Claude skill that stress-tests its own work

> Claude produces something, has it attacked by an **independent critic**, and only stops when it meets a **benchmark defined up front**. Not when it "feels done".

`grill-myself` is an [Agent Skill](https://code.claude.com/docs/en/skills) for Claude Code, Claude Desktop and claude.ai. Use it on a deliverable that has to be right: a Canvas App formula, a Power Automate flow, a PnP script, an HTML dashboard, an architecture plan or documentation.

| | |
|---|---|
| **Version** | 1.0.0 (see [CHANGELOG](CHANGELOG.md)) |
| **Works in** | Claude Code (CLI, VS Code, Desktop), claude.ai and Cowork |
| **Cost** | ~230 tokens per session (description), ~5k tokens per invocation + 1 critic run per round |
| **Sibling** | Counterpart of `grill-me`: there Claude grills **you**, here Claude grills **itself** |

---

## Contents

1. [Why this skill](#1-why-this-skill)
2. [How it works](#2-how-it-works)
3. [Installation](#3-installation)
4. [Usage](#4-usage)
5. [What you get back](#5-what-you-get-back)
6. [Requirements and limitations](#6-requirements-and-limitations)
7. [Updating and maintenance](#7-updating-and-maintenance)
8. [Troubleshooting](#8-troubleshooting)
9. [Repository layout](#9-repository-layout)

---

## 1. Why this skill

Ask an AI to "double-check its work" and you usually get a polite confirmation of what it already wrote. This skill breaks that pattern with three hard rules:

| Rule | What it prevents |
|---|---|
| **1. The bar is set before judging.** The benchmark is written before the draft. | Criteria being bent to fit the result afterwards. |
| **2. The critic is not the author.** A fresh subagent sees only the task, the benchmark and the draft. Never Claude's reasoning. | The reviewer being steered by the author's line of thought. |
| **3. The loop has an exit computed from numbers.** `PASS`, `PLATEAU` or `CAP`. | Endless iteration, or stopping because it "looks fine". |

**Use it** for deliverables where a mistake costs time or money: production formulas, flows, scripts that run against a tenant, customer-facing documentation, architecture decisions.

**Don't use it** for quick questions, small fixes or factual answers. Under ~30 lines, the skill itself suggests a lighter mode.

---

## 2. How it works

### 2.1 The process

```mermaid
graph TD
    START(["User: grill yourself"]) --> SIZE{"Small deliverable or 'quick'?"}
    SIZE -->|yes| LIGHT["Light mode: 5 criteria, max 2 rounds"]
    SIZE -->|no| FULL["Full mode: 5-8 criteria, max 5 rounds"]
    LIGHT --> P0
    FULL --> P0

    P0["Phase 0 - FRAME: deliverable, audience, hard constraints"] --> P1
    P1["Phase 1 - BENCHMARK: observable criteria, 2-3 Gates, threshold = 80 percent"] --> P2
    P2["Phase 2 - DRAFT v1 (or existing file = v1)"] --> C

    subgraph LOOP ["Phase 3 - Grill loop, per round"]
        C["3a Fresh critic subagent scores every criterion 0/1/2 with evidence"] --> V["Validate evidence: no valid quote or test output = 0"]
        V --> X{"3b Exit?"}
        X -->|not yet| T["3c Triage: Accept / Reject / Defer / Disputed"]
        T --> R["3d Snapshot vN, apply fixes"]
        R --> C
    end

    X -->|"PASS: all Gates = 2 and score at or above threshold"| D
    X -->|"PLATEAU: round 3+, no progress"| D
    X -->|"CAP: last round"| F["Final fixes + 1 scoring-only run"]
    F --> D
    D(["Phase 4 - DELIVER: verdict, grill log, residual risks, deliverable"])

    classDef phase fill:#E8F1FB,stroke:#2B6CB0,color:#1A365D
    classDef loop fill:#FFF5E6,stroke:#C05621,color:#652B19
    classDef exit fill:#E6F6EC,stroke:#2F855A,color:#1C4532
    class P0,P1,P2 phase
    class C,V,T,R loop
    class D,F exit
    style LOOP fill:#FFFBF5,stroke:#C05621,color:#652B19
```

> Diagram not rendering (e.g. an older Azure DevOps Server)? See [docs/img/flow.svg](docs/img/flow.svg).

### 2.2 Who sees what: critic independence

The key design principle is **information isolation**. The critic deliberately gets less context than the author, so it judges the work and not the intent.

```mermaid
sequenceDiagram
    actor U as User
    participant A as Claude (author)
    participant C as Critic (fresh subagent)

    U->>A: Task + grill yourself
    A->>A: Write frame + benchmark, BEFORE the draft
    A->>A: Produce draft v1
    loop Every round (max 5, light mode max 2)
        A->>C: Task frame + benchmark + draft + previously raised issues
        Note over A,C: Critic does NOT get: reasoning, earlier drafts, author's opinion
        C-->>A: Score per criterion with evidence, max 3 issues, expert verdict
        A->>A: Exit check: PASS, PLATEAU or CAP
        A->>A: Triage, snapshot, apply fixes
    end
    A-->>U: Verdict + grill log + residual risks + deliverable
```

> Fallback: [docs/img/sequence.svg](docs/img/sequence.svg). More detail on scoring, exits and triage in [docs/how-it-works.md](docs/how-it-works.md).

### 2.3 Scoring at a glance

- Every criterion scores **0** (fail), **1** (partial) or **2** (pass), always with **verbatim evidence** from the draft or from a test the critic ran. No evidence = 0.
- **Gates** (2 to 3 per benchmark) are the non-negotiable criteria, e.g. *delegation* for Power Fx or *Try/Catch* for a flow.
- **PASS** = every Gate at 2 **and** total ≥ `ceil(0.8 × max)`.
  Example: 7 criteria → max 14 → PASS from **12/14**, but only if every Gate is at 2.

---

## 3. Installation

Pick the route that matches where you use Claude. You only need one.

| Route | For | Updates |
|---|---|---|
| [**A. Plugin marketplace**](#a-claude-code-via-the-plugin-marketplace-recommended) (recommended) | Claude Code users | Centrally, via version number |
| [**B. Manual copy**](#b-claude-code-manual-install-no-marketplace) | Quick testing, no git access | Copy again manually |
| [**C. ZIP upload in claude.ai**](#c-claudeai-claude-desktop-and-cowork-zip-upload) | claude.ai, Desktop chat, Cowork | Re-upload, or org sharing |

> **In every command below**, replace `<org>`, `<project>` and `<repo>` with the real values of this repository.

### A. Claude Code via the plugin marketplace (recommended)

This repository is also a **plugin marketplace** (`m365-team-skills`) containing one plugin (`grill`) that holds the skill. Everyone gets the same version, and you roll out updates by bumping a version number.

**Step 1: add the marketplace.** In a Claude Code session, run the command for your host:

GitHub:

```text
/plugin marketplace add <org>/<repo>
```

Azure DevOps (use the full HTTPS clone URL; the `owner/repo` shorthand only works for github.com):

```text
/plugin marketplace add https://dev.azure.com/<org>/<project>/_git/<repo>
```

**Step 2: install the plugin.**

```text
/plugin install grill@m365-team-skills
```

**Step 3: verify.** Start a new session (or run `/reload-plugins`) and type `/grill`. You should see `/grill:grill-myself` in the list.

Prefer the shell over a session? That works too:

```bash
claude plugin marketplace add https://dev.azure.com/<org>/<project>/_git/<repo>
```

```bash
claude plugin install grill@m365-team-skills
```

#### Private repository? How authentication works

Claude Code simply runs `git` on your machine, **with interactive prompts disabled**. The marketplace has no token field. Your git must already be signed in before you run the command:

- **Azure DevOps:** clone the repository once manually with `git clone`. Git Credential Manager (bundled with Git for Windows) stores your sign-in, and Claude Code reuses it.
- **GitHub:** run `gh auth login`, then `gh auth setup-git`. No SSH key? Set the environment variable `CLAUDE_CODE_PLUGIN_PREFER_HTTPS=1`.

#### For the whole team at once (optional)

Want everyone working in a given project repository to get this marketplace automatically? Run this **once** in the root of that project repository and commit the `.claude/settings.json` it creates:

```bash
claude plugin marketplace add https://dev.azure.com/<org>/<project>/_git/<repo> --scope project
```

Teammates get the marketplace registered as soon as they trust the folder in Claude Code; after that they only need step 2. For a rollout across all machines (managed settings, auto-update), see [Manage plugins for your organization](https://code.claude.com/docs/en/plugins/org).

### B. Claude Code manual install (no marketplace)

Copy the skill folder to a location where Claude Code looks for skills.

| Scope | Target path | Available in |
|---|---|---|
| Personal | `~/.claude/skills/grill-myself/` | All your projects on this machine |
| Project | `<project-repo>/.claude/skills/grill-myself/` | Everyone working in that repo (commit the folder) |

**Windows (PowerShell).** Dry run first, then for real:

```powershell
.\scripts\Install-Skill.ps1 -Scope Personal -WhatIf
```

```powershell
.\scripts\Install-Skill.ps1 -Scope Personal
```

For a project repository: `.\scripts\Install-Skill.ps1 -Scope Project -ProjectPath C:\repos\my-project`.

**macOS / Linux:**

```bash
mkdir -p ~/.claude/skills && cp -R plugins/grill/skills/grill-myself ~/.claude/skills/
```

Start a new session and type `/grill-myself`. Note: installed manually the command is `/grill-myself`; installed via the plugin it is `/grill:grill-myself`.

### C. claude.ai, Claude Desktop and Cowork (ZIP upload)

**Prerequisite:** *Code execution and file creation* must be enabled (**Settings > Capabilities**). On a Team or Enterprise plan, an owner controls this in **Organization settings > Plugins & skills**.

1. Build the ZIP. It must contain the **folder** `grill-myself/` with `SKILL.md` inside, not just the file.

   Windows:

   ```powershell
   .\scripts\New-SkillPackage.ps1
   ```

   macOS / Linux:

   ```bash
   mkdir -p dist && (cd plugins/grill/skills && zip -r ../../../dist/grill-myself.zip grill-myself)
   ```

2. In claude.ai, go to **Customize > Skills**.
3. Click **+**, then **+ Create skill**, then **Upload a skill**.
4. Select `dist/grill-myself.zip`.
5. Toggle the skill on in your list.

**Sharing within your organization (Team/Enterprise):**

- **Share with colleagues:** click **⋯ > Share** next to the skill (an owner must enable *Share with organization* first). Recipients receive updates automatically.
- **Publish to org:** if your org allows it, an owner can make the skill installed by default or required for everyone.
- **Org sync from a repository:** **Organization settings > Plugins & skills** can sync a marketplace repository directly, but supports **GitHub and GitLab**, not Azure DevOps. If you host on Azure DevOps, use ZIP upload + Share.

> Skills you enable in claude.ai are also synced to Claude Code sessions signed in with the same account.

---

## 4. Usage

The skill only starts **when you explicitly ask for it**. An ordinary "improve this" deliberately does not trigger it.

| You type | Result |
|---|---|
| `/grill:grill-myself` (plugin) or `/grill-myself` (manual) | Starts explicitly |
| "Build this flow and **grill yourself** until it meets the bar" | Starts after producing the draft |
| "**Stress-test your answer**" / "**iterate until it meets the bar**" | Starts on your previous answer |
| "Grill yourself, but **quick**" | Light mode: 5 criteria, max 2 rounds |
| "Can you improve this?" | Does **not** start (ordinary improvement) |
| "Grill **me** on this plan" | Does **not** start: that is `grill-me` |

**Examples from our stack:**

```text
Write the Patch formula for the request form on the Dataverse table Requests.
2000-row delegation limit, users without a premium license. Grill yourself.
```

```text
Here is my PnP script that cleans up old versions in every document library.
Grill yourself on this existing script, focus on safety and throttling.
```

The skill ships a **starter benchmark** for each deliverable type (UI/HTML, Canvas App/Power Fx, Power Automate, PnP PowerShell, JS/TS/React/PCF, architecture, writing, skills/prompts). Claude tailors it to your task.

---

## 5. What you get back

Always in this order, so the verdict doesn't get buried under a long deliverable:

**1. Verdict**

```text
PASS in 3 rounds (12/14)
```

**2. Grill log**

| Round | Score | Gates | Accepted | Rejected (why) | Deferred / Disputed |
|---|---|---|---|---|---|
| 1 | 8/14 | Delegation: 1, Correctness: 2 | Hoist Filter into With() | Use premium connector (conflicts with licensing constraint) | - |
| 2 | 11/14 | Delegation: 2, Correctness: 2 | IfError around Patch | - | Offline mode (out of scope) |
| 3 | 12/14 | Delegation: 2, Correctness: 2 | - | - | - |

*(illustrative example)*

**3. Residual risks**: failing criteria, deferred and disputed issues, assumptions, and whether the critic actually tested or only read.

**4. The deliverable itself**: exactly the version the reported score was based on.

---

## 6. Requirements and limitations

- **An independent critic needs a subagent tool.** Claude Code and Cowork have one. Without it (e.g. in a plain claude.ai chat), the skill runs the critic as a separate step and labels the result `SELF-CRITIQUE (not independent)`. Usable, but less strict.
- **Cost scales with rounds.** Each round sends draft + benchmark + template to a new subagent. Claude states the mode, max rounds and max critic runs before starting.
- **No side effects while testing.** The critic may only test in a sandbox, read-only or dry-run mode. Never against a production tenant, never with real credentials, never anything that sends mail, writes data or deletes. If it can't be tested safely, it reviews statically and says so.
- **The benchmark is not a guarantee.** PASS means "meets the criteria defined up front". Read the residual risks and review it yourself before production.

---

## 7. Updating and maintenance

**Changing the skill:** edit `plugins/grill/skills/grill-myself/SKILL.md`.

**Rolling out a new version:**

1. Bump `version` in `plugins/grill/.claude-plugin/plugin.json` (e.g. `1.0.0` → `1.1.0`). Without a version bump, users do **not** receive the change.
2. Record the change in [CHANGELOG.md](CHANGELOG.md).
3. Validate locally:

   ```bash
   claude plugin validate .
   ```

4. Merge to `main` via a pull request.

**Pulling an update as a user:**

```text
/plugin marketplace update m365-team-skills
```

Or enable automatic updates: `/plugin` > **Marketplaces** > `m365-team-skills` > **Enable auto-update**.

**claude.ai users** (route C) re-upload the new ZIP, unless they received the skill via **Share**: then the update arrives automatically.

**Editing the diagrams:** the sources live in `docs/diagrams/*.mmd`. Edit them there, copy the code into this README, and re-export the SVG fallback (e.g. with the [Mermaid Live Editor](https://mermaid.live) or `npx @mermaid-js/mermaid-cli`).

---

## 8. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `marketplace add` fails on Azure DevOps with an auth error | Git wants to prompt for sign-in, but Claude Code disallows prompts | Clone the repository once manually so Git Credential Manager stores your sign-in |
| `owner/repo` can't find the Azure DevOps repository | The shorthand always means github.com | Use the full `https://dev.azure.com/...` URL |
| `Plugin "grill-myself" not found in marketplace` | You installed the skill name instead of the plugin name | `/plugin install grill@m365-team-skills` |
| Update doesn't arrive | `version` was not bumped | Bump the version in `plugin.json`, then `/plugin marketplace update` |
| ZIP upload in claude.ai fails | ZIP contains only `SKILL.md`, or folder name ≠ `name` in the frontmatter | Use `New-SkillPackage.ps1` or the `zip` command above |
| Skill doesn't start on its own | By design: it only triggers on explicit requests | Say "grill yourself" or use the slash command |
| Verdict shows `SELF-CRITIQUE (not independent)` | No subagent tool in this environment | Use Claude Code or Cowork for an independent critic |
| Mermaid diagram shows as code in Azure DevOps | Older Azure DevOps Server version | Use the SVGs in `docs/img/` |

---

## 9. Repository layout

```text
.
├── .claude-plugin/
│   └── marketplace.json          # Marketplace "m365-team-skills" (route A)
├── plugins/
│   └── grill/
│       ├── .claude-plugin/
│       │   └── plugin.json       # Plugin name + version (bump on every release)
│       └── skills/
│           └── grill-myself/
│               └── SKILL.md      # THE skill: single source of truth
├── scripts/
│   ├── Install-Skill.ps1         # Route B: copy to ~/.claude/skills (supports -WhatIf)
│   └── New-SkillPackage.ps1      # Route C: build dist/grill-myself.zip
├── docs/
│   ├── how-it-works.md           # Deeper explanation: scoring, exits, triage
│   ├── diagrams/*.mmd            # Mermaid sources for the diagrams
│   └── img/*.svg                 # Rendered fallback
├── CHANGELOG.md
└── README.md
```

`SKILL.md` lives in exactly **one** place. All three install routes read from that same folder, so versions can't drift apart.
