# Implementation Plan

## Task Format Template

Use whichever pattern fits the work breakdown:

### Major task only
- [ ] {{NUMBER}}. {{TASK_DESCRIPTION}}{{PARALLEL_MARK}}
  - {{DETAIL_ITEM_1}} *(Include details only when needed. If the task stands alone, omit bullet items.)*
  - _Requirements: {{REQUIREMENT_IDS}}_

### Major + Sub-task structure
- [ ] {{MAJOR_NUMBER}}. {{MAJOR_TASK_SUMMARY}}
- [ ] {{MAJOR_NUMBER}}.{{SUB_NUMBER}} {{SUB_TASK_DESCRIPTION}}{{SUB_PARALLEL_MARK}}
  - {{DETAIL_ITEM_1}}
  - {{DETAIL_ITEM_2}}
  - {{OBSERVABLE_COMPLETION_ITEM}} *(At least one detail item should state the observable completion condition for this task.)*
  - _Requirements: {{REQUIREMENT_IDS}}_ *(IDs only; do not add descriptions or parentheses.)*
  - _Boundary: {{COMPONENT_NAMES}}_ *(Only for (P) tasks. Omit when scope is obvious.)*
  - _Depends: {{TASK_IDS}}_ *(Only for non-obvious cross-boundary dependencies. Most tasks omit this.)*
  - _Phase: {{PHASE_ID}}_ *(Required only when the spec touches both `api/` and hand-written `web/` / `mobile_app/`. Values: `api`, `web`, `mobile`.)*

> **Parallel marker**: Append ` (P)` only to tasks that can be executed in parallel. Omit the marker when running in `--sequential` mode.
>
> **Optional test coverage**: When a sub-task is deferrable test work tied to acceptance criteria, mark the checkbox as `- [ ]*` and explain the referenced requirements in the detail bullets.

## Phase Grouping Layout (only when the spec spans `api/` and hand-written `web/` / `mobile_app/`)

When the spec changes both API-bucket paths (`api/`, `schema/`, `migration/`, plus generated dirs `web/src/generated/` / `mobile_app/lib/gen/`) and hand-written client paths, the task list MUST be grouped under per-phase headings in API → client order. `/kiro-impl` processes phases strictly in this order on a **single integrated branch** (no branch switching). PR splitting is performed later by `/create-split-prs`, which derives branch names from the current branch at split time.

```markdown
## Phase A: API

- [ ] 1. {{API major task}}
  - [ ] 1.1 {{API sub-task description}}
    - {{OBSERVABLE_COMPLETION_ITEM}}
    - _Requirements: 1.1, 1.2_
    - _Boundary: {{api component}}_
    - _Phase: api_

## Phase B: Web

- [ ] 2. {{Web major task}}
  - [ ] 2.1 {{Web sub-task description}}
    - {{OBSERVABLE_COMPLETION_ITEM}}
    - _Requirements: 2.1_
    - _Boundary: {{web component}}_
    - _Phase: web_
    - _Depends: 1.1_   <!-- Cross-phase dependency. Client work consumes API types committed earlier in the same branch. -->
```

Rules:
- Every executable sub-task carries exactly one `_Phase:_` annotation: `api`, `web`, or `mobile`.
- **One sub-task = one bucket**: A sub-task MUST touch files from only one bucket. If a unit of work naturally spans both, split into two sub-tasks (one per bucket) and link with `_Depends:_`. This keeps commit history bucket-pure so `/create-split-prs` can split mechanically.
- Cross-phase work goes in the later phase (typically generated-code reflection on the client side stays in the API phase because it lives under `web/src/generated/` / `mobile_app/lib/gen/`).
- `_Depends:_` may reference tasks in an earlier phase.
- Major task numbering continues across phases (Phase A uses 1./2., Phase B continues from there). Do NOT reset numbering per phase.
- The phase heading is informational; do NOT pre-record branch names. `/create-split-prs` derives them as `{current-branch}-{api|web|mobile|client}` at split time.
