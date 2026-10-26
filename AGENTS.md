<!-- mc:ctx:pc:start v=1 sha=acc5d5e8 -->
## PLAN CENTER (.pc/)

This project uses PLAN CENTER for plans. PLAN CENTER dictates only the FORMAT and LOCATION of plans, never how you plan. When you write a plan:

- Put the single master plan at `.pc/master_plan/master.md` (`type: master-plan`) and child plans at `.pc/plans/<id>.md` (`type: plan`, with `parent` linking up to the master).
- Start each document with YAML frontmatter per `.pc/guide/PLAN_FORMAT.md` (type, id, title, profile_version, created, updated, status, parent).
- Validate with `mc project validate` (the plan tooling lives in this binary: `internal/pc` + `mc project init`); view plans in the dashboard's PC zone (`#/pc/<projectId>`). The external `pc` CLI and `pc serve` are retired (plancenter repo archived).
- Reports, reviews, investigations, and long summaries go to `.pc/artifacts/<id>-<slug>.md` with artifact frontmatter (`type: artifact`, id, title, created/updated, `profile_version: 1`), NEVER the repo root. Reference the artifact from the owning plan's `artifacts:` list when one exists.
- Statuses: `open | ongoing | paused | finished | failed`.
- The ACTIVE plan is never declared directly, it is DERIVED: the single plan with `status: ongoing` that has no ongoing descendant (the "ongoing leaf"). Zero ongoing plans means PC shows no active plan at all.
- Therefore maintain the lifecycle in frontmatter every time you start or stop work on a plan:
  - Starting work: set that plan's `status: ongoing` and bump `updated: YYYY-MM-DD`.
  - Finishing or abandoning: set `finished` / `failed` (or `paused` when parking), bump `updated`, and set the next plan you pick up to `ongoing`.
  - Keep exactly ONE ongoing leaf whenever work is in flight; leave zero ongoing only when the project is genuinely between plans.
- This project's work is tracked in MC tasks (`mc task status` shows its namespace); MC tasks are the source of truth. Set `task: PREFIX-N` on the plan frontmatter; a task that belongs to more plans gets plan-level links (`mc task link <REF> --plan <id>`), never a `plan:` label. Search before you add (`mc task search`), mark the task `active`, comment progress (`mc task comment`), and finish it with `mc task done` (`mc task --help` lists the rest). If the task authority answers unavailable, say so, keep coding, and reconcile explicitly when it is back; never claim a write that failed.
- Stages: units of work inside a plan are always called stages (never phase, slice, step, milestone or wave).
  - A plan with two or more stages declares them all in frontmatter `stages:` (quoted ids `"1"`, `"2"`; an inserted stage takes a letter suffix such as `"1b"`, never renumber), each backed by its own MC task (stage `task: PREFIX-N`, a child of the plan's `task:`); `mc project stage <plan> --create-tasks` creates and links the missing ones.
  - The body has one `### Stage <id>: <title>` heading per stage with **Scope**, **Acceptance**, **Checkpoint (Morty)** and **Log**; progress narrative goes into that stage's Log.
  - Move the stage at every boundary: `mc project stage <plan> <stage>` when you start it, `--checkpoint` when you stop for Morty's test, the next stage (or `--done`) when he accepts. It moves the stage's task on the task authority first, then writes the plan's mirror. A stage-backed task refuses generic state edits, so the stage command is the only way to move it. If the mirror write fails after the move, run `mc project stage <plan> --sync`. Never edit a stage's `status` or `task:` by hand.
- After any plan-doc edit, run `mc project validate` and fix findings before you finish.

See `.pc/guide/PLAN_FORMAT.md` for the full contract and examples.
<!-- mc:ctx:pc:end -->
