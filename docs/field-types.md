# Field types and calculated columns

Set types in **View Configurator → Field Mapping** (or on a view’s `columns` in Postgres). Types drive list formatting, filter operators, Excel import/export coercion, and form controls. Leave **(none)** to fall back to OpenAPI / sample-value inference.

## Field types

| Type | Role |
| ---- | ---- |
| `text` | Strings; text filter operators (`ilike`, …) |
| `number` | Numeric display/filters; cast in SQL filters |
| `date` | Date-only |
| `datetime` | Timestamps |
| `boolean` | True/false controls and filters |
| `json` | Object JSON; JsonViewer in the form |
| `array` | Array JSON; JsonViewer in the form |
| `calculated` | Client-side JavaScript over the current row (see below) |

Legacy labels are normalized (`varchar` → `text`, `int4` → `number`, `jsonb` → `json`, `calc` / `formula` → `calculated`, …).

For ordinary columns, **Source** is a PostgREST path (`id`, `jsondata->>Name`, …). For `calculated`, Source is JavaScript (not sent to PostgREST; cannot filter/sort on the server).

## Calculated columns

1. Add or pick a column in Field Mapping.
2. Set **Type** to `calculated`.
3. Put JavaScript in **Source**.

```json
{
  "full_label": {
    "type": "calculated",
    "path": "[fields.Code, fields.Name].filter(Boolean).join(' — ')"
  }
}
```

Use `fields.FieldName` for flat access (top-level columns and `jsondata` keys). Spaced names get an alias (`Object Type` → `fields.ObjectType`); bracket form also works: `fields['Object Type']`. Full row: `record.id`, `record.jsondata.…`. Other calculated columns are not available — repeat the expression if needed.

### Examples

**Last segment of a dotted type**

```js
(fields.ObjectType || '').split('.').pop().toLowerCase()
```

**Concatenate several fields**

```js
[fields.Code, fields.Name, fields.Module].filter(Boolean).join(' / ')
```

```js
`${fields.Code || ''} — ${fields.Name || ''}`
```

```js
(fields.FirstName || '') + ' ' + (fields.LastName || '')
```

**Concat with replace / strip**

Strip a prefix, then join:

```js
[
  String(fields.ObjectType || '').replace(/^COM\.ABBR\./, ''),
  fields.Code,
  fields.Name,
]
  .filter(Boolean)
  .join(' | ')
```

Spaces → underscores, then join:

```js
[
  String(fields.Code || '').replace(/\s+/g, '_'),
  String(fields.Name || '').replace(/\s+/g, '_'),
]
  .filter(Boolean)
  .join('-')
```

Swap one token for another:

```js
String(fields.Status || '').replace(/InProgress/g, 'In progress')
```

Remove a middle segment (e.g. drop `.Staticdata.`):

```js
String(fields.ObjectType || '').replace(/\.Staticdata\./g, '.')
```

Keep only digits from a code, then append name:

```js
String(fields.Code || '').replace(/\D/g, '') + ' ' + (fields.Name || '')
```

**Substring / slice / pad**

```js
String(fields.Code || '').slice(0, 8)
```

```js
String(fields.Code || '').substring(3, 10)
```

```js
String(fields.Id || '').padStart(6, '0')
```

**Fallback / coalesce**

```js
fields.DisplayName || fields.Name || fields.Code || record.id
```

```js
fields.Name != null && fields.Name !== '' ? fields.Name : '(unnamed)'
```

**Boolean / flag from other fields**

```js
!!(fields.Code && fields.Name)
```

```js
fields.Status === 'Active' ? 'Y' : 'N'
```

**Numbers**

```js
Number(fields.Qty || 0) * Number(fields.Price || 0)
```

```js
(Number(fields.Amount || 0)).toFixed(2)
```

**Dates (ISO strings on the row)**

```js
String(fields.updated_at || '').slice(0, 10)
```

```js
[String(fields.created_at || '').slice(0, 10), fields.created_by]
  .filter(Boolean)
  .join(' · ')
```

**Nested jsondata**

```js
record.jsondata?.Address?.City || ''
```

```js
[
  record.jsondata?.Address?.City,
  record.jsondata?.Address?.Country,
]
  .filter(Boolean)
  .join(', ')
```

**Multi-step (locals + `return`)**

```js
const t = String(fields.ObjectType || '');
const short = t.replace(/^COM\.ABBR\./, '').split('.').pop();
return [short, fields.Code, fields.Name].filter(Boolean).join(' · ');
```

```js
const code = String(fields.Code || '').trim().replace(/\s+/g, '_');
const name = String(fields.Name || '').trim();
if (!code && !name) return '';
return code && name ? `${code}: ${name}` : code || name;
```

### Calculated `/data/…` or `/pages/…` path columns

If a calculated column’s value is an app path (`/data/{schema}/{table}`, `/data/.../record/{id}`, or `/pages/...`), it is used as the href (app base applied). You can also set another column’s **Link** to `@ThatColumn` — when that field resolves to a `/data/…` or `/pages/…` path, that path is the href (not “table name + cell as record id”).

```js
'/data/' + String(fields.table || '').replace(/\./g, '/')
```

```js
'/data/' +
  String(fields.table || '').replace(/\./g, '/') +
  '/record/' +
  encodeURIComponent(String(fields.id ?? ''))
```

Example: `Table Link` calculated as above; `Table` column Link = `@Table Link`.

### FK link from a calculated table name

Set another column’s **Link** to `@collection` when `collection` is calculated to a table name:

```json
{
  "collection": {
    "type": "calculated",
    "path": "(fields.ObjectType || '').split('.').pop().toLowerCase()"
  },
  "code": {
    "path": "jsondata->>Code",
    "type": "text",
    "link": "@collection"
  }
}
```

Tree client-only `Level` / `Path` columns are separate — see [framework-tables.md](framework-tables.md#auto-fields-level-and-path).
