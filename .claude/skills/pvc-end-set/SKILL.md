---
name: pvc-end-set
description: Closes a work set in one go. Captures the session's learnings into CLAUDE.md with the pvc-claude-md rules, brings the project's file-based memory notes up to date (the folder Claude Code keeps per project under the active config dir), commits the project locally in the PVC format, commits the memory folder too when it is its own git repo, then hands the user the one thing Claude cannot run, /compact. Nothing extra has to run, so it works on any machine. Use when the user says "end set", "close the set", "wrap up the session", "end of session", "save and commit", or asks for CLAUDE.md plus memory plus commit plus compact together.
metadata:
  author: pvc
  version: "0.1.4"
license: MIT
---

<!-- SPDX-License-Identifier: MIT -->

# pvc-end-set

One command for the four things the user asks for at the end of every block of work, in the order they have to happen: learnings into CLAUDE.md, memory for the next session, local commits, then /compact. Memory is the project's file-based notes, the folder Claude Code itself keeps per project. Nothing has to be running for that, so the same skill works on a Windows PC, a Mac and a headless Linux box.

## When to Use

- The user says the set, block, or session is over and wants it closed properly
- The user asks for CLAUDE.md, memory, commit and compact in one breath
- A roadmap step just got ticked and the tree has uncommitted work plus lessons worth keeping

## What This Skill Does Not Do

- Does NOT run /compact. Claude cannot. The last two lines of the output hand the user a ready-to-copy `/compact` line, under 80 characters with the set's topic and the keep clause, to paste as is
- Does NOT call a memory server or any MCP tool. Memory here is files
- Does NOT push, add a remote, or set an upstream, in either repo
- Does NOT run git init in the memory folder. A folder that is not a repo gets its notes written and its commit skipped, with one line saying so. Making it a repo is the user's call
- Does NOT tick roadmap steps or write specs. Do that before calling this
- Does NOT audit CLAUDE.md's four pillars in full. It runs the session-learnings part of pvc-claude-md only

## Trigger Examples

Should trigger on:

- "end set"
- "close the set"
- "wrap up the session"
- "can we do pvc-claude-md, save to memory, commit and compact after?"

Should NOT trigger on:

- "commit this" (pvc-git-commit-message-local alone)
- "update CLAUDE.md with what we learned" (pvc-claude-md alone)

## Where Things Live

| Part | Path | How to find it |
|---|---|---|
| project | the folder the session runs in | `git rev-parse --show-toplevel` |
| memory | `<config dir>/projects/<slug>/memory` | rule below |

The config dir is the value of `CLAUDE_CONFIG_DIR` when that variable is set (a setup with more than one profile sets it), otherwise `~/.claude`. The slug comes from the absolute path of the repo's main working tree. Every character other than the ASCII letters `A` to `Z` and `a` to `z` and the digits `0` to `9` is turned into a dash, so an accented letter becomes a dash too: `/srv/my_app` becomes `-srv-my-app`, `D:\work\site.v2` becomes `D--work-site-v2`. In a linked git worktree the main working tree is the path on the first line of `git worktree list --porcelain`, and not the folder of the worktree: every worktree of a repo shares the memory folder of the main checkout. A slug of more than 200 characters is cut there and ends in a dash and a short hash. The `MEMORY.md` index in that folder is the same file the memory system loads at session start, so if the folder holds one, the path is right. When the folder you worked out is missing, list `<config dir>/projects` and look for the folder of this project first. Only when none is there has the memory system written nothing for this project; create the folder with the first note. When the settings name a folder in `autoMemoryDirectory`, that folder is the memory folder and this rule does not apply.

Two profiles on one machine can share one memory folder (their `projects` folders linked to one store) or keep separate ones. The skill always works in the folder of the ACTIVE profile and prints the path it wrote to. Never run git in the parent `projects` folder; it holds every project's transcripts.

## The Mechanic

Run the four parts in this order. Each part is one clear block of the output, and a skipped part says why in one line.

1. **Learnings into CLAUDE.md.** Follow the Lab Notes and session-learnings rules of `pvc-claude-md`: one `### YYYY-MM-DD: short title` entry per gotcha, dead end, or non-obvious approach from this session, 1-2 sentences each, newest at the bottom. Rotate past 10 into `LABS.md` and fix the header count. Add a project rule only when the session settled one. Strip secrets, absolute home paths and client names. Nothing worth keeping: write "CLAUDE.md: nothing new this set" and move on.
2. **Memory notes.** Check the memory folder against the session: every durable fact (a decision, a correction from the user, a project state change, a pointer) that is not yet in a note gets one, following the note format the memory system prescribes (frontmatter with name, description, type; a Why and a How to apply line for feedback and project notes; a one-line pointer in MEMORY.md). Update an existing note rather than adding a twin, and delete notes proven wrong. Then, when the memory folder is its own git repo (`git -C <folder> rev-parse --show-toplevel` answers with that folder, not a parent), run the commit skill there. Not a repo: write "Memory: N notes updated, folder is not a git repo, no commit" and go on. Nothing new: write "Memory: notes already current" and still check for uncommitted edits made earlier in the session.
3. **Commit the project.** Follow `pvc-git-commit-message-local` end to end in the project: read the tree, pick the bump, write the PVC message (no quotes, no backticks, blank line after the headline), stage the named paths for this set including the CLAUDE.md and LABS.md changes, commit, report the short hash. Clean tree: print its refusal line and go on.
4. **Hand over /compact.** End with two lines. The first is a ready-to-copy compact line built from the set: `/compact Set <vX.Y.Z> Closed (<Topic>), Keep Open Items, Paths, Hashes`, in Title Case like a commit headline. The version is the commit just made, or the last one on a clean tree. The topic is two to four words that say what the set was about, taken from the headline of that same commit (`Photo Backup Set`, `Worker Retry Loop`), so the line reads as a record of the set in the terminal history instead of the same line after every set. The keep clause tells the summarizer what must survive: the open items, the exact paths and the commit hashes; the summarizer reads the whole chat for the rest. No date in the line: the commit carries its own date. Keep the whole line under 80 characters, because a terminal wraps a longer line, the copy keeps that wrap as a line break, and the paste then sends only the first half to /compact; the fixed words take about 62 characters, so the topic gets about 17, and when the line runs long, shorten the topic, never the keep clause. The second line is `Then say what you want next.`

## What To Print

One shape, four labelled blocks, then the hand-over line. Keep each block to two or three lines. A skipped part keeps its label and one line of reason.

```
CLAUDE.md: 2 lab notes added, 2 rotated to LABS.md, 1 pointer line added.
Memory: 3 notes updated, 1 added; committed 889d5fa v0.0.2 - Added the Backup Drive Note
Commit: 45df16e v0.0.2 - Closed the Photo Backup Set
/compact Set v0.0.2 Closed (Photo Backup Set), Keep Open Items, Paths, Hashes
Then say what you want next.
```

Same shape when the memory folder is not a repo:

```
CLAUDE.md: 1 lab note added.
Memory: 2 notes updated (~/.claude/projects/-srv-my-app/memory), folder is not a git repo, no commit.
Commit: 3c1e0a2 v0.3.1 - Fixed the Worker Retry Loop
/compact Set v0.3.1 Closed (Worker Retry Loop), Keep Open Items, Paths, Hashes
Then say what you want next.
```

Refusal shape, when nothing at all changed since the last set:

```
CLAUDE.md: nothing new this set.
Memory: notes already current, nothing to commit.
Commit: nothing to commit, working tree is clean.
/compact Set v0.3.1 Closed (Worker Retry Loop), Keep Open Items, Paths, Hashes
Then say what you want next.
```

## Resilience

- **Memory folder missing:** when the search of Where Things Live finds no folder of this project under `<config dir>/projects`, create it, write the notes and a MEMORY.md index, say so in the Memory block, skip the memory commit, continue with the project commit.
- **CLAUDE_CONFIG_DIR unset while several config dirs exist:** use `~/.claude`, since that is what a plain `claude` call uses, and print the path so a wrong profile is visible at once.
- **Commit fails (hook, lock, nothing staged) in either repo:** show the git error, leave the tree as it is, still print the hand-over line so the user can compact and retry.
- **Re-run on the same set:** CLAUDE.md gets no duplicate notes (check the titles first), memory notes get no twins (check the names first), both commits refuse on a clean tree. Safe to call twice.

## Installation

Copy this folder into the project as `.claude/skills/pvc-end-set/`. The command name comes from the folder name. It needs `pvc-claude-md` and `pvc-git-commit-message-local` in the same project. Restart Claude Code so the skill loads. Verify by asking "What skills are available?" and confirming pvc-end-set appears.
