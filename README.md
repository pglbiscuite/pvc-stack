# pvc-stack

> A Claude Code setup in one `.claude` folder: skills, hooks, output styles and a status line.

Made by Alexandru Bogdan. This is the setup I use with Claude Code every day, cleaned up and put under one MIT license. The repo has the same shape as the `.claude` folder of a project, so you can copy the whole folder into a project, or take one item.

<!-- stack:catalog:start -->

**Skills**

| Skill | Version | What it does |
|---|---|---|
| [pvc-claude-md](.claude/skills/pvc-claude-md/) | 0.0.14 | Audit, improve and update a CLAUDE.md file, and rotate old lab notes. |
| [pvc-end-set](.claude/skills/pvc-end-set/) | 0.1.4 | Close a work set in one go: lab notes, memory notes, a local commit and the /compact line. |
| [pvc-git-commit-message-local](.claude/skills/pvc-git-commit-message-local/) | 0.4.2 | Write a commit message in the PVC format and commit locally, with no push. |
| [pvc-roadmap-writer](.claude/skills/pvc-roadmap-writer/) | 0.2.1 | Write and update linear roadmap files with tick-box steps and one finish line. |

**Output styles**

| Output style | Version | What it does |
|---|---|---|
| [eli5](.claude/output-styles/eli5.md) | - | Short plain answers in Simplified Technical English: what was done, did it work, what to do next. |
| [tldr-eli10](.claude/output-styles/tldr-eli10.md) | - | One TLDR line first, then one line per idea in plain words. |

**Hooks**

| Hook | Version | What it does |
|---|---|---|
| [timestamp](.claude/hooks/timestamp/) | 0.2.0 | Put the date, the weekday and the time in front of every prompt. |

**Templates**

| Template | Version | What it does |
|---|---|---|
| [claude-md](templates/claude-md/) | 0.1.0 | A starter CLAUDE.md of voice rules and chat tone: plain words and no AI tells. |

<!-- stack:catalog:end -->

## What Is in the Folder

```text
.claude/
├── settings.json    switches the timestamp hook on
├── skills/          one folder per skill, with its SKILL.md
├── hooks/           one folder per hook, with its settings lines
├── output-styles/   one file per output style
└── statusline/      one folder per status line, with the script and the settings lines
```

## Install

1. Get the files:

   ```bash
   git clone https://github.com/pglbiscuite/pvc-stack
   ```

   On a PC with no Git, use the **Code** button on the GitHub page and pick **Download ZIP**.

2. Pick one of the two ways.

   **The whole setup.** Copy the `.claude` folder into your project. You get every skill, every output style and the timestamp hook in one step. If your project has a `.claude/settings.json` already, keep your file, and add the hook block from `.claude/hooks/timestamp/README.md` to it.

   **One item.** Copy what you want into the `.claude` folder of your project. Keep the names: Claude Code takes the command name of a skill from its folder name.

   | Item | Copy | Then |
   |---|---|---|
   | A skill | its folder to `.claude/skills/` | start a new session |
   | An output style | its file to `.claude/output-styles/` | start a new session and pick it with `/output-style` |
   | A hook | nothing | paste the settings lines from its README into a settings file |
   | A status line | its folder to a place that stays | paste the settings lines from its README into a settings file |

   The skill `pvc-end-set` needs `pvc-claude-md` and `pvc-git-commit-message-local` next to it in `.claude/skills/`.

3. Ask Claude "What skills are available?" and check that the skill is in the list.

To use an item in every project on your machine, copy it to the `.claude` folder in your user folder.

## What Runs by Itself

One thing. The file `.claude/settings.json` switches on the hook `timestamp`. Before each prompt it runs one command that prints the date and the time, so Claude knows what day it is. The command reads no file and sends nothing.

When you start Claude Code in a folder for the first time, it asks if you trust the folder. The hook does not run before you say yes.

To switch it off, delete the `hooks` block in `.claude/settings.json`.

Nothing else runs by itself. A skill runs when you call it, or when Claude picks it for a request that fits its description. An output style applies when you pick it. The status line starts only after you add its lines to a settings file of your own.

## Update

Run `git pull` in your copy of the repo, then copy the item again. If you changed your copy, compare the two before you copy over it.

## License

MIT. See [LICENSE](LICENSE).

Claude and Claude Code are trademarks of Anthropic. This project is independent. It is not affiliated with, endorsed by, or sponsored by Anthropic.
