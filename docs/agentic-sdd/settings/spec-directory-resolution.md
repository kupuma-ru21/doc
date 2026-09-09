# Spec Directory Resolution

Spec directories under `docs/agentic-sdd/specs/` use the naming convention:

```
docs/agentic-sdd/specs/{YYYYMMDDHHmmss}_{feature-name}/
```

- `YYYYMMDDHHmmss` is a 14-digit timestamp (no separators) generated at directory creation time (typically by `/kiro-discovery` or `/kiro-spec-init`).
- `{feature-name}` is the canonical kebab-case feature identifier stored in `spec.json` as `feature_name`.

All spec-touching skills receive `{feature-name}` as their CLI argument and must resolve it to the actual directory path using this algorithm.

## Resolution Algorithm

Given an argument `ARG`:

### Step 1: Detect input form

If `ARG` matches the pattern `^[0-9]{14}_[A-Za-z0-9._-]+$` (14 digits, underscore, then feature-name), treat it as a **full directory name**:

- Verify `docs/agentic-sdd/specs/{ARG}/` exists.
- If yes → resolved path is `docs/agentic-sdd/specs/{ARG}/`. Skip remaining steps.
- If no → error: `"Spec directory 'docs/agentic-sdd/specs/{ARG}/' does not exist."`

Otherwise, treat `ARG` as a bare `{feature-name}` and proceed to Step 2.

### Step 2: Glob match by feature-name

Glob the following pattern (the leading character class is intentionally strict to avoid collisions with feature-names that themselves contain `_`):

```
docs/agentic-sdd/specs/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_{ARG}/
```

### Step 3: Handle match count

- **0 matches** → error:
  ```
  No spec directory found for '{ARG}'. Run /kiro-discovery or /kiro-spec-init first.
  ```

- **1 match** → use that directory as the resolved path.

- **2+ matches** → error and list all candidates with their `created_at` from `spec.json`, sorted oldest-first. Ask the user to disambiguate by re-invoking with the full directory name. Example output:
  ```
  Multiple spec directories match '{ARG}':
    - docs/agentic-sdd/specs/20260507143022_{ARG}/  (created_at: 2026-05-07T14:30:22Z)
    - docs/agentic-sdd/specs/20260511091344_{ARG}/  (created_at: 2026-05-11T09:13:44Z)

  Re-run with the full directory name, e.g.:
    /kiro-spec-status 20260511091344_{ARG}
  ```

## Notes

- `feature_name` in `spec.json` remains the canonical name and is **not** the directory name. The directory name's prefix is purely a filesystem-sortable convenience.
- Manually-created directories without the 14-digit prefix (e.g., `docs/agentic-sdd/specs/{feature-name}/`) are **not** matched by the strict Glob pattern and will return 0 matches. Re-create them via `/kiro-discovery` or `/kiro-spec-init` to register them properly.
- Inventory-style globs (e.g., listing all specs) should use `docs/agentic-sdd/specs/[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]_*/` to enforce the same convention.
