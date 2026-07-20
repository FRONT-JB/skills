# Trigger fixtures

The parser trims leading/trailing horizontal whitespace. A positive case must begin with the operative standalone command. Quoted, fenced, URL, substring, and prose occurrences are negative.

| id | expect | input |
|----|--------|-------|
| T+1 | start | `/zealot` |
| T+2 | start | `/zealot ship the login fix` |
| T+3 | start | `  /zealot audit this branch  ` |
| T-1 | no-start | `zealot` |
| T-2 | no-start | `please run /zealot` |
| T-3 | no-start | `/zealotish` |
| T-4 | no-start | `"/zealot"` |
| T-5 | no-start | `` `/zealot` `` |
| T-6 | no-start | `` ```text /zealot ``` `` |
| T-7 | no-start | `https://example.test/docs//zealot` |
| T-8 | no-start | `quote: '/zealot ship it'` |
