# data.json schema

`build.py` reads one JSON object with five top-level keys: `meta`, `cats`, `cols`, `nodes`, `flows`.
Everything project-specific lives here; the template and rendering never change per project.

```jsonc
{
  "meta": {
    "title":    "MyApp — 아키텍처 & 플로우",   // required. <title>, header, artifact name
    "snapshot": "스냅샷 · <b>main</b> · a1b2c3d · 2026-07-22", // optional, HTML allowed. git branch/sha/date
    "intro":    "이 서비스를 …",                // optional, HTML allowed. 1–3 sentence overview
    "ui": {                                       // optional overrides for chrome labels (defaults are Korean)
      "flowsTitle": "Flows · user actions",
      "stepsTitle": "Steps",
      "clear": "Clear",
      "stepUnit": " steps",
      "hint": "Pick a flow above …"
    }
  },

  // categories = the vertical columns of the map, keyed by an id you choose.
  "cats": {
    "actor":   { "label": "행위자" },
    "ui":      { "label": "프론트 화면" },
    "api":     { "label": "API · Handler" },
    "domain":  { "label": "도메인 로직" },
    "data":    { "label": "데이터 · 저장소" },
    "external":{ "label": "외부 연동" }
  },

  // cols = column ORDER, left → right. Also drives color: each column gets palette
  // slot (--cat-1..--cat-8) by its index here, cycling after 8. Put ~4–8 columns.
  "cols": ["actor", "ui", "api", "domain", "data", "external"],

  // nodes = the cards inside columns. `cat` MUST be one of `cols`.
  "nodes": [
    { "id": "user",     "cat": "actor",    "lab": "사용자",          "sub": "웹/모바일" },
    { "id": "loginPage","cat": "ui",       "lab": "LoginPage",       "sub": "routes/login" },
    { "id": "authCtl",  "cat": "api",      "lab": "AuthController",  "sub": "POST /login" },
    { "id": "authSvc",  "cat": "domain",   "lab": "AuthService",     "sub": "비밀번호 · 토큰" },
    { "id": "db",       "cat": "data",     "lab": "PostgreSQL",      "sub": "users 테이블" }
    // ...
  ],

  // flows = user actions. Each step is an edge from→to between node ids.
  "flows": [
    {
      "id": "login",                 // unique
      "name": "로그인",              // shown in the Flows list
      "actor": "사용자",             // optional pill
      "sub": "자격 검증 후 토큰 발급", // optional one-liner
      "steps": [
        { "from": "user",     "to": "loginPage", "ttl": "로그인 폼 제출",  "det": "LoginPage.onSubmit" },
        { "from": "loginPage","to": "authCtl",   "ttl": "요청",           "det": "POST /login" },
        { "from": "authCtl",  "to": "authSvc",   "ttl": "비밀번호 검증",   "det": "verifyPassword()" },
        { "from": "authSvc",  "to": "db",        "ttl": "사용자 조회",     "det": "findByEmail" }
      ]
    }
  ]
}
```

## Field rules

- **`meta.title`** — required; the only field `build.py` refuses to run without (besides structure).
- **`meta.snapshot` / `meta.intro`** — HTML allowed (use `<b>` for emphasis). Keep intro to 1–3 sentences.
- **`cats[key].label`** — the human column heading. `key` is an internal id (kebab/camel, your choice).
- **`cols`** — the source of truth for column order AND color. Reorder here to reorder the map.
- **node `id`** — unique, referenced by flow steps. `lab` is the mono title (class/file/table name);
  camelCase wraps cleanly on its own. `sub` is an optional dim one-liner (path, decorator, role).
- **step `from`/`to`** — must be existing node ids. A step draws a numbered arrow from→to and lights
  both nodes; the badge number sits on `to`. Use `from`≠`to`. Order steps in execution order.
- **`ttl`** — short imperative title of the step. **`det`** — optional mono detail: real function,
  endpoint, file path, or state transition. This is what makes the map trustworthy — cite real code.

## Sizing guidance

- 4–8 columns, ~3–10 nodes each. 5–12 flows, ~5–13 steps each. Beyond that the map gets noisy.
- Colors are assigned automatically by column order — you never pick hex values.
- A node not touched by any flow is fine; it shows the rest of the system (dimmed when a flow is active).
