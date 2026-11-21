# Acceptance pass

Read the issue. For every Acceptance checkbox, decide met, partial, or missing, and
quote the diff line that proves it. Report requirements that are missing, partial,
implemented wrong, or unrequested scope. Each finding needs a file and line and a
failure scenario.

Return JSON only:

{"findings":[{"severity":"high|medium|low","file":"path","line":1,"scenario":"what fails and how","claim":"one sentence"}]}

Return {"findings":[]} when you find nothing.
