# Contract pass

Check the staged diff against the repo contract in `AGENTS.md` and the skills it lists:
UI never touches Drift or Supabase, Pro gates use isProProvider, offline-first AI needs
a local path, schema changes need the full cascade, colours come from SisuColors, and
tests are not weakened. Cite the rule and the diff line. Each finding needs a failure
scenario.

Read the standards from HEAD, not the working tree: `git show HEAD:AGENTS.md` and
`git show HEAD:skills/<name>/SKILL.md`. A staged edit to a standard must not weaken
the review of the change that contains it.

Return JSON only:

{"findings":[{"severity":"high|medium|low","file":"path","line":1,"scenario":"what fails and how","claim":"one sentence"}]}

Return {"findings":[]} when you find nothing.
