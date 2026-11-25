# pvc-end-set

<p align="center"><img src="assets/pvc-end-set-banner.jpg" alt="pvc-end-set"></p>

![version](https://img.shields.io/badge/version-v0.1.6-blue) ![type](https://img.shields.io/badge/Claude%20Code-skill-7C5CFF) ![license](https://img.shields.io/badge/license-MIT-green)

> Closes a work set in one command: lab notes, memory notes, a local commit and the line for /compact.

A Claude Code skill for the end of a block of work. Made by Pro Vibe Coding. One phrase, "end set", runs the four steps that keep a project easy to pick up again: the lessons of the session go into `CLAUDE.md`, the memory notes of the project get current, the work gets a local commit, and you get a ready line to paste for `/compact`. It grew out of daily use, where those four requests came as one long sentence at the end of every session.

## Table of Contents

- [Key Features](#key-features)
- [Install](#install)
- [Usage](#usage)
- [How It Works](#how-it-works)
- [Output Rubric](#output-rubric)
- [Known Limitations](#known-limitations)
- [Changelog](#changelog)
- [License](#license)

## Key Features

- Four steps in a fixed order: `CLAUDE.md`, memory, commit, the `/compact` line.
- Lab notes follow the rules of `pvc-claude-md`: dated entries, the latest 10 in `CLAUDE.md`, older ones in `LABS.md`.
- Memory is the notes folder that Claude Code keeps per project, its auto memory. No server and no MCP tool has to run. When auto memory is off, the skill writes no notes and says so.
- The commit follows `pvc-git-commit-message-local`: the PVC format, local only, never a push.
- The `/compact` line names the topic of the set, and the version when a commit has one. It stays under 80 characters, a house rule from a terminal that broke a longer line in two when it was copied.
- Safe to run twice: no duplicate notes, and a clean tree gets a refusal line in place of an empty commit.

## Install

This is a Claude Code skill. Pick the path that matches where you want it available.

**From the pvc-stack repo:** clone `https://github.com/pglbiscuite/pvc-stack`, then copy the folder `.claude/skills/pvc-end-set` to one of the places listed here. Keep the folder name `pvc-end-set`: the `name` in the frontmatter sets the command, the folder name also runs the skill, and the two should match.

The skill needs two other skills from the same repo, `pvc-claude-md` and `pvc-git-commit-message-local`, installed where your sessions load skills: the project's `.claude/skills/` or your personal skills folder. Copying all three into one folder is the simple way.

### Project-local (one repo)

Drop the folders into the repo's `.claude/skills/`:

```text
your-project/
└── .claude/
    └── skills/
        ├── pvc-end-set/
        │   ├── SKILL.md
        │   ├── README.md
        │   ├── assets/          (README artwork)
        │   └── REQUIREMENTS.md
        ├── pvc-claude-md/
        └── pvc-git-commit-message-local/
```

### Personal (all your projects)

Copy the three folders into your user-level skills directory, side by side:

```text
Windows:        %USERPROFILE%\.claude\skills\
macOS / Linux:  ~/.claude/skills/
```

With `CLAUDE_CONFIG_DIR` set, the personal folder is `skills/` inside that directory.

### Polyrepo / monorepo

Place the three folders once in `.claude/skills/` at the root of the repository. Claude Code loads project skills from the folder you start it in and from every parent folder up to the repository root, so a session started in a subfolder finds them too. A `.claude/skills/` above the repository root does not load, and the skill needs a git repository anyway.

### As part of a plugin

If you bundle skills as a Claude Code plugin, include `pvc-end-set/` and its two helper skills in the plugin's `skills/` directory. Claude Code finds the skills in that folder when the plugin loads. The command then carries the plugin's name: `/<plugin-name>:pvc-end-set`.

### Verify the install

A running session picks up the new folders. For a plugin install, run `/reload-plugins`. In a session, ask:

```text
What skills are available?
```

Confirm `pvc-end-set` appears in the list. If it does not, run `/reload-skills`. The skill needs git and the two helper skills, see [REQUIREMENTS.md](REQUIREMENTS.md).

## Usage

Say it in plain language at the end of a block of work, or type `/pvc-end-set`. These phrasings usually load the skill:

```text
end set
close the set
can we do pvc-claude-md, save to memory, commit and compact after?
```

A good moment is the end of a session, or right after a roadmap step gets ticked while the tree holds uncommitted work and lessons worth keeping. For a plain commit, use `pvc-git-commit-message-local`. For a `CLAUDE.md` update alone, use `pvc-claude-md`.

Agent response. One block per step, then the line to paste:

```text
CLAUDE.md: 2 lab notes added, 2 rotated to LABS.md, 1 pointer line added.
Memory: 3 notes updated, 1 added (~/.claude/projects/-srv-my-app/memory); committed 889d5fa v0.0.2 - Added the Backup Drive Note
Commit: 45df16e v0.0.2 - Closed the Photo Backup Set
/compact Set v0.0.2 Closed (Photo Backup Set), Keep Open Items, Paths, Hashes
Then say what you want next.
```

Copy the `/compact` line and paste it. Claude cannot run that command for you.

When nothing changed since the last set, each block says so:

```text
CLAUDE.md: nothing new this set.
Memory: notes already current (~/.claude/projects/-srv-my-app/memory), nothing to commit.
Commit: nothing to commit, working tree is clean.
/compact Set v0.3.1 Closed (Worker Retry Loop), Keep Open Items, Paths, Hashes
Then say what you want next.
```

## How It Works

| Step | What happens | Rules from |
| --- | --- | --- |
| 1. Learnings | Each gotcha, dead end or non-obvious approach of the session becomes a dated lab note in `CLAUDE.md` | `pvc-claude-md` |
| 2. Memory | While auto memory is on, each durable fact of the session gets a note in the memory folder of the project, or an existing note gets updated | the auto memory format: a `type` field and one line in `MEMORY.md` |
| 3. Commit | One local commit of the project in the PVC format | `pvc-git-commit-message-local` |
| 4. Hand-over | A ready `/compact` line with the topic of the set, and the version when a commit has one | this skill |

Before the memory step, the skill checks that auto memory is on. It looks first at Claude Code's own instructions for the session: when they name an auto memory folder, auto memory is on and the skill uses that folder. When they name none, the switches decide: when `CLAUDE_CODE_DISABLE_AUTO_MEMORY` is `1`, or `autoMemoryEnabled` is `false` in your settings and that variable is not `0`, it writes no notes and says so in the Memory line. The same goes for a session in a self-hosted environment, other than a Claude Tag session, where auto memory is off by default.

When the session names no auto memory folder, the memory folder is the folder named in the `autoMemoryDirectory` setting when you set one. With `CLAUDE_CONFIG_DIR` and `CLAUDE_CODE_PROJECT_DIR_NAME` both set, it is `<config dir>/projects/<that name>/memory`. Otherwise it is `<config dir>/projects/<slug>/memory`. The config dir is the value of `CLAUDE_CONFIG_DIR` when that variable is set, otherwise `~/.claude`. The slug comes from the full path of the repo's main working tree, and every git worktree of a repo shares one memory folder. The rest of the naming rule is observed, not documented by Claude Code: every character other than the ASCII letters and the digits `0` to `9` becomes a dash, so `/srv/my_app` becomes `-srv-my-app`, and a slug of more than 200 characters is cut there and ends in a dash and a short hash. When the folder is missing, the skill looks in `<config dir>/projects` for the folder of the project before it makes one, first for the folder that holds the transcript of the session. The skill prints the path it used.

When the memory folder is a git repo of its own, the notes get a commit too. When it is not, the notes are written and the skill says that it made no commit there.

## Output Rubric

Every run is checked against these dimensions.

| Dimension | Pass criteria |
| --- | --- |
| order | The three labelled blocks come in the fixed order, then the `/compact` line. A skipped step keeps its label and gives one line of reason. |
| lab_notes | Dated entries of 1 to 2 sentences. No duplicate title. At most 10 entries stay in `CLAUDE.md`. |
| memory | Each durable fact of the session is in a note, unless a `CLAUDE.md` file, the code or the git history already holds it. No twin notes and no secret in a note. The folder path is printed. When auto memory is off, one line says so and no note is written. |
| commit | One local commit in the PVC format, or the refusal line on a clean tree. No push and no new remote. |
| hand_over | The `/compact` line is under 80 characters and names the topic of the set. It names the version too when a commit has one. |
| privacy | No secret, no home path and no client name in a lab note. |

## Known Limitations

- Does NOT run `/compact`. Only you can.
- Does NOT push, add a remote or set an upstream.
- Does NOT make the memory folder a git repo. That is your call.
- Does NOT tick roadmap steps or write specs.
- Does NOT work alone: it needs `pvc-claude-md` and `pvc-git-commit-message-local` installed too.
- Memory notes need auto memory on, the default in a local session. With `CLAUDE_CODE_DISABLE_AUTO_MEMORY` set to `1`, with `autoMemoryEnabled` set to `false` while that variable is not `0`, or in a session in a self-hosted environment, other than a Claude Tag session, where it is off by default, the skill writes no notes and says so in the Memory line.
- When the repository's own settings set `autoMemoryDirectory` while `permissions.blockReadsOutsideWorkingDirectories` is on, Claude Code saves no notes to that folder, so the skill writes none and says so in the Memory line.

## Changelog

- **v0.1.6 (2026-11-25).** The skill checks that auto memory is on before the memory step. It looks first at Claude Code's own instructions for the session: when they name an auto memory folder, auto memory is on and that folder is the memory folder. When they name none, `CLAUDE_CODE_DISABLE_AUTO_MEMORY` and `autoMemoryEnabled` decide, and a session in a self-hosted environment, other than a Claude Tag session, runs with auto memory off by default. When it is off, the Memory line says so and no note is written. The same goes for a folder that the repository's own settings set in `autoMemoryDirectory` while `permissions.blockReadsOutsideWorkingDirectories` is on, since Claude Code saves no notes there. The description no longer claims "save and commit", "wrap up the session" or "end of session", and it names what the skill is not for: a plain commit or a `CLAUDE.md` update alone. Every git call of the memory commit names the memory folder with `git -C`, so it cannot commit the project by mistake. The memory folder follows `CLAUDE_CODE_PROJECT_DIR_NAME` when it is set beside `CLAUDE_CONFIG_DIR`, and when the folder is missing, the skill first looks for the folder that holds the transcript of the session. Memory notes leave out what a `CLAUDE.md` file, the code or the git history already holds, never hold a secret, and match the fields of the notes already there. The memory repo test looks for a `.git` entry first and calls git only when there is one, works with Windows paths, and reports a git error as an error. Closing the set counts as the request to commit, so the commit skill commits and does not stop at the message. With staged and unstaged changes both in the tree, the commit step asks which to commit, in auto mode too, and takes the staged changes alone only when no question can be asked. The install check runs in the open session: `/reload-skills` finds a skill it does not list, and a plugin install needs `/reload-plugins`. SKILL.md lost the sections that only help a person: when to use, trigger examples and installation, all kept in this README.
- **v0.1.5 (2026-11-24).** The `/compact` line leaves out the version when no commit has one. Every Memory line of the output shows the path of the memory folder. README.md and REQUIREMENTS.md name the `autoMemoryDirectory` setting, as SKILL.md does. REQUIREMENTS.md gives the git identity commands with a value. The personal install puts the three folders side by side in the user skills folder. Smaller fixes in the pages: the count of labelled blocks, the place of the two helper skills and `assets/` in the folder tree.
- **v0.1.4 (2026-11-23).** Moved into the pvc-stack repo under MIT. One `LICENSE` file at the root of the repo covers every skill, so the skill folder carries no license files of its own. This README is new.
- **v0.1.3 (2026-09-26).** The `/compact` line carries the topic of the set in brackets, two to four words from the commit headline.
- **v0.1.2 (2026-09-25).** The `/compact` line lost its date and went under 80 characters. A terminal had wrapped a longer line, and the paste sent only its first half.
- **v0.1.1 (2026-09-25).** The hand-over became a ready-to-copy `/compact` line with the set version and a keep clause.
- **v0.1.0 (2026-09-17).** First version with file-based memory notes: the paths come from the active config dir and the project slug, and the memory folder gets a commit only when it is a repo.

## License

MIT. One license covers the whole pvc-stack repo: see the `LICENSE` file at the root of https://github.com/pglbiscuite/pvc-stack.

Claude and Claude Code are trademarks of Anthropic. This project is independent. It is not affiliated with, endorsed by, or sponsored by Anthropic.
