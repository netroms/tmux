# PLAN CENTER: Plan Format Guide

This is the authoritative contract for how plans are written and where they live in this project. PLAN CENTER (`pc`) dictates **format and location only**, never *how* you plan or what your plans say. Any planning workflow can produce these files.

> Compatibility: frontmatter is OKF-compatible (every document has a non-empty `type`), so OKF tooling can read these files. The plan *semantics* below are PLAN CENTER's own.

## Where plans live

```
.pc/
  master_plan/master.md     # exactly one master plan (type: master-plan)
  plans/<id>.md             # child plans (type: plan)
  artifacts/<id>-<slug>.*   # optional artifacts (type: artifact); single self-contained file
  guide/PLAN_FORMAT.md      # this file
```

Only `master_plan/`, `plans/`, and `artifacts/` are scanned for plan documents. Anything else under `.pc/` is ignored.

## Frontmatter profile (`profile_version: 1`)

Every document starts with a YAML frontmatter block.

| Key | Required on | Meaning |
| --- | --- | --- |
| `type` | all | `master-plan` \| `plan` \| `artifact` |
| `id` | all | stable, unique slug (e.g. `checkout-redesign`) |
| `title` | all | human-readable name |
| `profile_version` | all | `1` |
| `created` / `updated` | all | ISO dates (`YYYY-MM-DD`) |
| `status` | master-plan, plan | `open` \| `ongoing` \| `paused` \| `finished` \| `failed` |
| `parent` | plan | bundle-relative path to the parent (e.g. `/plans/foo.md`); `null` only on the master |
| `description` | recommended | one-sentence summary |
| `task` | optional | the plan's MC task ref (`PREFIX-N`), the parent of its stage tasks; Tier-2 hint when a non-finished (`open`/`ongoing`/`paused`) plan lacks one |
| `artifacts` | optional | list of bundle-relative artifact paths (`/artifacts/<file>`); `.pc/`-prefixed or slash-less forms (`.pc/artifacts/<file>`, `artifacts/<file>`) are normalized to that form |
| `order` | optional | integer for sibling ordering |
| `stages` | optional | ordered list of stage entries, see [Stages](#stages); each needs `id` and `title`, and should carry a `task` ref |

### Task keys

Work is tracked in MC tasks (`mc task status` shows the project's namespace). `task: PREFIX-N` is the only task key: on the plan it names the plan's task, on a stage the stage's task. Plan membership is a plan link in the task authority (`mc task link <REF> --plan <id>`), never a label in the file. A plan file that still carries a retired key (an old task-ref key on the plan or a stage, or an old label key) gets the Tier-2 hint `RETIRED_TASK_KEY`: replace it with `task:`. `mc project convert-keys [--dry-run]` rewrites every plan and master plan file of a project that way: a ref converts only when it names a task of that project in the authority, others are left and reported. Only those key lines change (`updated:` stays). Nothing is committed: commit the files path-scoped.

## Stages

Stages are the one unit of work inside a plan. A plan declares them as an ordered list under `stages:`; the list order is the plan order, and nothing else orders stages. The key is optional. A plan with a single deliverable may have none; a plan with two or more stages declares them all up front, each with its own MC task under the plan's `task` (stage key `task`).

```yaml
task: PROJ-691                    # the plan's MC task; stage tasks are its children
stages:
  - id: "1"                       # required; ^[0-9]+[a-z]?$, unique in the plan; quote it
    title: Projects and live sessions   # required; short, matches the body heading
    status: done                  # MIRROR of the stage task's state, see the table
    task: PROJ-692                # the stage's MC task (Tier-2 hint when missing)
    started: 2026-10-09           # optional; set when the stage first becomes active
    finished: 2026-10-09          # optional; set when it becomes done or skipped
    plan: /plans/child.md         # optional; a child plan that carries this stage
    note: "..."                   # optional; one line: why skipped, why reopened
  - id: "1b"                      # inserted after the owner's test: letter suffix, never renumber
    title: Rendering and layout fixes
    status: checkpoint
    task: PROJ-695
    started: 2026-10-10
```

Stage status and the MC task state it mirrors (the six statuses are the task states themselves, one to one):

| Stage status | Meaning |
| --- | --- |
| `planned` | not started (default when `status` is absent) |
| `active` | an agent is working on it |
| `checkpoint` | built and handed over: waiting for the owner's test, feedback or go |
| `blocked` | started but stuck; `note` says on what |
| `done` | accepted |
| `skipped` | deliberately not done; `note` says why |

**The task authority is the truth, `stages[].status` is a mirror of it.** Move a stage only with `mc project stage <plan> <stage> [--checkpoint|--block|--done|--skip|--back]` (with no flag it starts the stage): it changes the stage task in the authority, then rewrites the mirror (status, dates, note, `task:` refs). Never edit a stage's `status` by hand. `mc project stage <plan> --create-tasks` creates and links every missing stage task (title `Stage <id>: <title>`, parent = the plan's `task:`) and writes their refs. `mc project stage <plan> --sync` repairs a stale mirror from the authority without changing any task.

**The current stage is derived, never declared**, the way the active plan is: the first stage in list order whose status is `active`, `checkpoint` or `blocked`. None means the plan is between stages, not started, or done.

Ids: `0` is allowed (prerequisites, spikes). A stage added later takes a letter suffix of the stage it follows (`1b`, `1c`), so ids used in commits, task titles and chat never change. The parser accepts a bare YAML number (`id: 1`) and normalizes it to a string; always quote. Nested dates are `YYYY-MM-DD`.

Body shape:

```markdown
## Stages

### Stage 1: Projects and live sessions

- **Scope**: what this stage builds.
- **Acceptance**: numbered, observable criteria.
- **Checkpoint (Morty)**: what Morty tests or decides before the next stage.
- **Log**: dated one-liners: built (`abc1234`), feedback, reopened, skipped and why.
```

Rules:

- One `## Stages` section; one `### Stage <id>: <title>` heading per declared stage, in list order. The frontmatter title wins in the UI; the heading anchors the stepper link.
- Stages are the only unit word. Inside a stage, sub-steps are a checklist (`- [ ]`), not slice, phase or step headings. A stage too big for one section gets its own child plan and points to it with `plan:`.
- Progress narrative goes into the stage's **Log**, not into dated paragraphs at the top of the plan or a separate `## Status` section.
- The checkpoint is part of every stage that ships something the owner can use.
- A stage heading is `### Stage <id>:` outside fenced code blocks; fenced examples never count.

Stage validation (`mc project validate` stays offline, no task calls):

| Tier | Code | Rule |
| --- | --- | --- |
| 1 | `BAD_STAGES` | `stages` is not a list of maps, or an entry lacks `id` or `title` |
| 1 | `BAD_STAGE_ID` | `id` does not match `^[0-9]+[a-z]?$` |
| 1 | `DUP_STAGE_ID` | two stages share an id in one plan |
| 1 | `BAD_STAGE_STATUS` | `status` outside `planned`, `active`, `checkpoint`, `blocked`, `done`, `skipped` |
| 1 | `BAD_STAGE_REF` | malformed `plan` path, or an unparseable date |
| 1 | `BAD_STAGE_TASK_REF` | malformed stage `task` ref (expected `PREFIX-N`) |
| 2 | `STAGE_NO_TASK` | a stage of a non-finished plan has no `task` (fix: `mc project stage <plan> --create-tasks`) |
| 2 | `DUP_STAGE_TASK` | two stages share a `task` ref |
| 2 | `RETIRED_TASK_KEY` | a plan file still carries a retired task or label key; replace it with `task:` |
| 2 | `MULTI_CURRENT_STAGE` | more than one stage is `active`/`checkpoint`/`blocked` |
| 2 | `NO_CURRENT_STAGE` | an `ongoing` plan with stages has no current stage and not every stage is `done`/`skipped` |
| 2 | `STAGE_OPEN_ON_TERMINAL` | a `finished`/`failed` plan has an `active`, `checkpoint`, `blocked` or `planned` stage |
| 2 | `STAGE_HEADING_MISSING` | a declared stage has no `### Stage <id>:` heading in the body |
| 2 | `STAGE_UNDECLARED` | a `### Stage <id>:` heading has no frontmatter entry |
| 2 | `SKIP_WITHOUT_NOTE` | a `skipped` stage has no `note` |
| 2 | `USE_STAGES` | a non-finished plan has two or more phase/slice/step/milestone/wave headings and no `stages` |

## Validation (`mc project validate`)

Two tiers, and the difference matters:

- **Tier 1, format conformance (fails the build, non-zero exit):** parseable frontmatter, `type` in the vocabulary, all required keys present, `status` in the enum, unique `id`s, understood `profile_version`, a well-formed plan `task` ref (`BAD_TASK_REF`), and well-formed `stages` (codes `BAD_STAGES`, `BAD_STAGE_ID`, `DUP_STAGE_ID`, `BAD_STAGE_STATUS`, `BAD_STAGE_REF`, `BAD_STAGE_TASK_REF`; see the Stages section).
- **Tier 2, workflow hints (advisory, always exits 0):** exactly one master, every plan's `parent` chain reaches the master without cycles, at most one `ongoing` plan per root-to-leaf path, every non-finished (`open`/`ongoing`/`paused`) plan carries a `task` link (hint `NO_TASK`), and the stage hints (`RETIRED_TASK_KEY`, `STAGE_NO_TASK`, `DUP_STAGE_TASK`, `MULTI_CURRENT_STAGE`, `NO_CURRENT_STAGE`, `STAGE_OPEN_ON_TERMINAL`, `STAGE_HEADING_MISSING`, `STAGE_UNDECLARED`, `SKIP_WITHOUT_NOTE`, `USE_STAGES`). These are reminders, never gates: PC does not police how you organize work.

The **active plan** is the single `ongoing` leaf (an `ongoing` plan with no `ongoing` descendant). Orphans (plans whose parent chain does not reach the master) are rendered but never selected as active.

## Examples

A master plan:

```markdown
---
type: master-plan
id: my-project
title: My Project: Master Plan
description: The essence of the project.
status: ongoing
parent: null
created: 2026-06-25
updated: 2026-06-25
profile_version: 1
---

# My Project: Master Plan

...the idea, the why, the high-level shape...
```

A child plan:

```markdown
---
type: plan
id: add-search
title: Add full-text search
description: Let users search records.
status: open
parent: /master_plan/master.md
created: 2026-06-25
updated: 2026-06-25
profile_version: 1
task: DEMO-12
---

# Add full-text search

...scope, design, steps, acceptance criteria...
```
