# pvc-stack

This repo is a Claude Code setup to copy from. The items sit under `.claude/` (skills, hooks, output styles, a status line) and under `templates/`. `README.md` lists every item.

## When You Work in This Repo

- To install an item for the user, read the README of that item first, then copy the item into the user's own project. Never copy over a file of the user that has the same name: show the difference and ask. An output style has no README: follow the install table in `README.md`.
- `.claude/settings.json` switches on one hook, `timestamp`, which prints the date and the time before each prompt. The file holds nothing else. Do not add permissions, environment values or other keys to it.
- A hook or a status line in the user's own project needs its settings lines in a settings file there. Show the lines and ask before you change a settings file.
- Do not change the items in this clone. Change an item in the user's own project, where it was copied to. A local edit here can make the next `git pull` stop until it is committed or stashed.
