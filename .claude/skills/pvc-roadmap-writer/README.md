# pvc-roadmap-writer

<p align="center"><img src="assets/pvc-roadmap-writer-banner.jpg" alt="pvc-roadmap-writer"></p>

![version](https://img.shields.io/badge/version-v0.2.2-blue) ![type](https://img.shields.io/badge/Claude%20Code-skill-7C5CFF) ![license](https://img.shields.io/badge/license-MIT-green)

> Writes and updates linear roadmap files: tick-box steps, one bold TLDR line per step, one testable finish line.

A Claude Code skill for anyone who plans work in steps and wants one file to follow. Made by Pro Vibe Coding. It turns an idea, a spec or a raw voice note into a markdown roadmap of 5 to 9 ordered steps, and it keeps that file current: a finished step gets its tick, its date and a record of what was done. The format came out of real projects where a long plan was hard to follow.

## Table of Contents

- [Key Features](#key-features)
- [Install](#install)
- [Usage](#usage)
- [The Roadmap Format](#the-roadmap-format)
- [Output Rubric](#output-rubric)
- [Known Limitations](#known-limitations)
- [Changelog](#changelog)
- [License](#license)

## Key Features

- One markdown file with four parts: title, steps, dated ticks, finish line.
- 5 to 9 numbered tick-box steps in dependency order. Each opens with a bold Title Case action phrase under 10 words.
- At most 3 plain lines of detail per step. Deeper work becomes tick-box sub-steps (`4b`, `4c`).
- A ticked step carries its date and states what was done or decided, so the roadmap is also the record.
- One `Done when` statement that a stranger can answer with yes or no.
- Three handled paths: a new roadmap, an update pass, and one question when the finish line is missing.
- An existing roadmap gets updated in place. The skill never writes a second file next to it.

## Install

This is a Claude Code skill. Pick the path that matches where you want it available.

**From the pvc-stack repo:** clone `https://github.com/pglbiscuite/pvc-stack`, then copy the folder `.claude/skills/pvc-roadmap-writer` to one of the places listed here. Keep the folder name `pvc-roadmap-writer`: a project or personal skill takes its command name from the directory name.

### Project-local (one repo)

Drop the folder into the repo's `.claude/skills/`:

```text
your-project/
└── .claude/
    └── skills/
        └── pvc-roadmap-writer/
            ├── SKILL.md
            ├── README.md
            ├── assets/          (README artwork)
            └── REQUIREMENTS.md
```

### Personal (all your projects)

Copy the folder to your user-level skills directory:

```text
Windows:        %USERPROFILE%\.claude\skills\pvc-roadmap-writer\
macOS / Linux:  ~/.claude/skills/pvc-roadmap-writer/
```

### Polyrepo / monorepo

Place it once at `.claude/skills/pvc-roadmap-writer/` in the directory you open Claude Code from. The skill is available whenever you launch Claude Code from that root.

### As part of a plugin

If you bundle skills as a Claude Code plugin, include `pvc-roadmap-writer/` in the plugin's `skills/` directory. Claude Code finds the skills in that folder when the plugin loads.

### Verify the install

Start a new Claude Code session, then ask:

```text
What skills are available?
```

Confirm `pvc-roadmap-writer` appears in the list. The skill needs nothing installed beyond Claude Code, see [REQUIREMENTS.md](REQUIREMENTS.md).

## Usage

Ask in plain language. Any of these phrasings trigger the skill:

```text
make a roadmap for the photo backup script
roadmap this idea
plan this out in steps
turn this idea into a step-by-step plan
tick step 2, wrote the script today
```

Agent response for a new roadmap. The file is the deliverable, so the chat gets two lines:

```text
docs/photo-backup-roadmap.md
5 steps, 1 pre-ticked
```

Agent response for an update pass:

```text
Step 2 ticked: backup.py written at tools/, drive check included
```

When the source holds no testable end state, the skill writes nothing and asks one question:

```text
What is the checkable statement that means this is DONE? Finish the sentence: this is done when a stranger can ___
```

## The Roadmap Format

The file the skill writes for the first example:

```markdown
# Photo Backup Script, Roadmap

One command that copies the photo folder to an external drive and proves that the copy is complete. Linear. Do the steps in order, tick as you go. The statement at the bottom is the finish line.

## Steps

1. [x] **Decide Where the Backup Goes** (decided 2026-07-15)
   An external drive, not a cloud folder.
   One dated folder per run.
   Old runs stay.

2. [ ] **Write backup.py**
   Input: a source folder and a target drive.
   Copy every file into the same folder layout.
   Refuse to run when the drive is missing.

3. [ ] **Wire in the Verify Pass**
   Hash every source file and its copy.
   Any mismatch stops the run, exit nonzero.

4. [ ] **Test on a Throwaway Folder**
   Copy 50 mixed files to a scratch folder.
   Back it up and diff the result.
   Every file there, zero mismatches.

   - [ ] **4b: Rerun with a File Changed During the Copy**
     The race case. The run must flag the changed file, not report OK.

5. [ ] **Run the First Real Backup**
   The full photo folder goes first.
   Run the command and spot-check ten files.
   Note the runtime.

## Done when

> The photo folder gets a verified copy on the external drive with one command, and a file that differs shows up in the report.
```

The rules behind it:

1. 5 to 9 steps. Fewer means the idea is one task, more means merge steps or split the project.
2. Steps follow dependency order. Two steps that could swap places get merged.
3. One decision per decision step. Its options sit in the detail lines until the step is ticked.
4. Bold titles are Title Case. Detail lines stay normal sentences.
5. One idea per line.
6. Work done before the roadmap exists arrives ticked, with its real date.

## Output Rubric

Every roadmap the skill writes is checked against these dimensions before it is saved.

| Dimension | Pass criteria |
| --- | --- |
| linear_dependency | Steps are in true dependency order. No two adjacent steps could swap freely. |
| tldr_first | Every step opens with a bold Title Case action phrase under 10 words. Detail is 3 lines at most. |
| record_keeping | Every ticked step carries a date and states what happened, not what was planned. |
| finish_line | The `Done when` statement is answerable with yes or no by someone outside the project. |
| voice | Zero em dashes. Zero words that the project's CLAUDE.md bans. |
| sub_step_discipline | Sub-steps appear only for work that can be ticked on its own. No line packs two deliverables. |
| edge_case_coverage | Finished work arrives ticked, a decision step lists its options, over 9 steps brings the merge-or-split question, and an existing roadmap is updated in place. |

## Known Limitations

- Does NOT write daily task lists or session todos.
- Does NOT write implementation plans with file contents and test commands.
- Does NOT write specs or design documents. It can turn a finished spec into a roadmap.
- Does NOT keep ledgers that only list phase names.
- Does NOT do the steps. It writes the plan file and keeps it current.

## Changelog

- **v0.2.2 (2026-11-24).** The worked examples put one idea on each detail line now, as the skill's own rules ask. The tree under Install lists the `assets/` folder.
- **v0.2.1 (2026-11-23).** Moved into the pvc-stack repo under MIT. One `LICENSE` file at the root of the repo covers every skill, so the skill folder carries no license files of its own. The worked example is a photo backup script now, and this README is new.
- **v0.2.0 (2026-07-18).** Sub-steps: tick-box items under a step (`4b`, `4c`) for work that runs deeper than the headline, each with its own detail lines and dates.
- **v0.1.0 (2026-07-15).** First packaged version: linear steps, TLDR first, dated ticks and one finish line.

## License

MIT. One license covers the whole pvc-stack repo: see the `LICENSE` file at the root of https://github.com/pglbiscuite/pvc-stack.

Claude and Claude Code are trademarks of Anthropic. This project is independent. It is not affiliated with, endorsed by, or sponsored by Anthropic.
