# Plan for correcting brandvariant tree_new2 (not applied)

Verified in the live view configurator on 2026-10-18:

- Both `docs.brandvariant|tree` and `docs.brandvariant|tree_new2` have `tree.fetchPerLevel: true`.
- `docs.brandvariant|tree` is the correct reference tree. Leave it unchanged.
- The checked-in `scripts/views/docs.brandvariant|tree.sql` omits the flag, so it does not represent the current live configuration. The earlier explanation that the live views use different loaders was incorrect.

## Cause

`resolveLevelFieldColumn` in `src/features/records/recordsDataController.ts` resolves each field against the entity Default model. It first matches the tree column's path, then its key, then uses identity/name fallbacks, and finally falls back to the tree column's path.

The working tree uses `Manufacturer Code`. On brandfamily, this key matches the entity Default column even though its path differs from the brandvariant tree column. The checked-in brandfamily Default maps that key to `jsondata->Manufacturers->0->>Code`. The working tree's own column remains `jsondata->Manufacturer->>Code`; it does not need to be changed to the array path.

The new tree uses `bm`. Its tree path is `jsondata->Manufacturer->>Code`, and brandfamily Default has no `bm` key. Both matches fail for this parent field, so the resolver falls back to the tree path. Missing parent values make families appear as roots.

There is also a name-reference mismatch: the family level refers to `bfm`, while its mapped column is `bfn`. A name fallback can mask this typo.

## Configuration-only correction to apply later

Use the working live tree's mapped keys in tree_new2. Rename column keys and their tree-level references together, preserving their existing paths and presentation settings:

- `bm` → `Manufacturer Code`
- `bmn` → `Manufacturer Name`
- `bf` → `Brand Family Code`
- `bfn` → `Brand Family Name`; change the level's erroneous `bfm` reference to this same key
- `bg` → `Brand Group Code`
- `bgn` → `Brand Group Name`
- `n` → `Name`
- Keep leaf `id` (case-insensitive matching supports the reference tree's `ID`).

Keep `fetchPerLevel: true`, the four entity tables, sorting, and existing JSON paths. Parent fields are inferred from the preceding level's ID key. Do not globally replace the manufacturer path with an array path: these paths belong to different entities.

If short aliases must remain supported, a separate resolver enhancement is needed: explicitly map tree aliases to entity Default fields rather than assuming the tree path applies on every entity. Do not implement this by hardcoding brandfamily paths or changing the working tree.

## Verification after a future change

Reload tree_new2 and compare it with the live reference using the same filters, limits, sorting, and expansion state. Families should nest under manufacturers; groups under families; variants under groups. Verify the family names and inspect the per-entity requests to confirm correct parent selection. Compare counts only with equal fetch limits. No view, application code, or SQL seed was changed as part of saving this plan.
