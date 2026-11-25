---
name: pvc-end-set
description: "Closes a work set, one block of work, in one go: the session's learnings go into CLAUDE.md with the pvc-claude-md rules, the project's auto memory notes get current, the project gets a local commit in the PVC format, and the user gets a ready line to paste for /compact, which Claude cannot run. Use when the user says 'end set', 'close the set', or 'I am done for today, note what we learned, commit it and give me the compact line', or asks for CLAUDE.md plus memory plus commit plus compact together. Not for a plain commit (pvc-git-commit-message-local) or a CLAUDE.md update alone (pvc-claude-md)."
metadata:
  author: pvc
  version: "0.1.6"
license: MIT
---

<!-- SPDX-License-Identifier: MIT -->

# pvc-end-set

A set is one block of work, closed when the user says so. This skill does the four things that close it, in the order they have to happen: learnings into CLAUDE.md, memory for the next session, local commits, then the /compact line. Memory is the project's auto memory, the folder of notes Claude Code keeps per project.

## What This Skill Does Not Do

- Does NOT run /compact. Claude cannot. The last two lines of the output hand the user a ready-to-copy `/compact` line, under 80 characters with the set's topic and the keep clause, to paste as is
- Does NOT call a memory server or any MCP tool. Memory here is files
- Does NOT push, add a remote, or set an upstream, in either repo
- Does NOT run git init in the memory folder. A folder that is not a repo gets its notes written and its commit skipped, with one line saying so. Making it a repo is the user's call
- Does NOT tick roadmap steps or write specs. Do that before calling this
- Does NOT audit CLAUDE.md's four pillars in full. It runs the session-learnings part of pvc-claude-md only

## Where Things Live

| Part | Path | How to find it |
|---|---|---|
| project | the folder the session runs in | `git rev-parse --show-toplevel` |
| memory | `<config dir>/projects/<slug>/memory` | rules below |

The config dir is the value of `CLAUDE_CONFIG_DIR` when that variable is set, otherwise `~/.claude`. Turn `~` into an absolute path before any git call, since a shell can hand `~` to git as is. When Claude Code's own instructions for this session name an auto memory folder, that folder is the memory folder. When they name none, it is the first of these that applies:

1. The folder that `autoMemoryDirectory` names in the settings. Claude Code saves no notes to that folder when the value comes from the repository's settings while `permissions.blockReadsOutsideWorkingDirectories` is `true` in any settings file. The repository's settings are the project's `.claude/settings.json` and a `.claude/settings.local.json` that git tracks or that sits in a symlinked `.claude`. Then write none, and print the Off line of step 2 with that reason.
2. `<config dir>/projects/<name>/memory`, when `CLAUDE_CONFIG_DIR` and `CLAUDE_CODE_PROJECT_DIR_NAME` are both set and `<name>` is the value of the second.
3. `<config dir>/projects/<slug>/memory`, the slug made from the absolute path of the repo's main working tree. Every worktree of a repo shares that one folder; in a linked worktree the main working tree is the path on the first line of `git worktree list --porcelain`. The character rule is observed, not documented: every character other than the ASCII letters `A` to `Z` and `a` to `z` and the digits `0` to `9` turns into a dash, an accented letter too (`/srv/my_app` becomes `-srv-my-app`, `D:\work\site.v2` becomes `D--work-site-v2`), and a slug of more than 200 characters is cut there and ends in a dash and a short hash.

The `MEMORY.md` index in that folder is the same file the memory system loads at session start, so if the folder holds one, the path is right. When the folder of case 3 is missing, look under `<config dir>/projects` for the folder that holds `${CLAUDE_SESSION_ID}.jsonl`, the transcript of this session: when the session started at the root of the main checkout, its `memory` subfolder is the memory folder. Otherwise list `<config dir>/projects` and look for the folder of this project. A folder still missing after that, or missing when the session names it or in case 1 or 2, means the memory system has written nothing for this project yet; create it with the first note.

Work in the folder of the active config dir and print the path written to. Never run git in the parent `projects` folder; it holds every project's transcripts.

## The Mechanic

Run the four parts in this order. Each part is one clear block of the output, and a skipped part says why in one line.

1. **Learnings into CLAUDE.md.** Follow the Lab Notes and session-learnings rules of `pvc-claude-md`: one `### YYYY-MM-DD: short title` entry per gotcha, dead end, or non-obvious approach from this session, 1-2 sentences each, newest at the bottom. Rotate past 10 into `LABS.md` and fix the header count. Add a project rule only when the session settled one. Strip secrets, absolute home paths and client names. Nothing worth keeping: write "CLAUDE.md: nothing new this set" and move on.
2. **Memory notes.** First check that auto memory is on. Claude Code's own instructions for this session come first: when they name an auto memory folder, auto memory is on and that folder is the memory folder. When they name none, fall back to the two switches. `CLAUDE_CODE_DISABLE_AUTO_MEMORY` set to `1` turns it off and set to `0` keeps it on, whatever the settings say. Otherwise it is off when `autoMemoryEnabled` is `false` in the settings that apply: the project's `.claude/settings.local.json` outranks its `.claude/settings.json`, which outranks `settings.json` in the config dir, and a managed settings file outranks all three. A session in a self-hosted environment, other than a Claude Tag session, runs with auto memory off by default. Off: write "Memory: auto memory is off (<what turned it off>), no notes written" and go on to step 3. On: check the memory folder against the session. Every durable fact (a decision, a correction from the user, a project state change, a pointer) that is not yet in a note gets one, unless a CLAUDE.md file already says it (step 1's additions included), or the code or git history shows it. A note is one topic file with YAML frontmatter whose `type` is `user`, `feedback`, `project` or `reference` (match the fields of the notes already there), plus a one-line pointer in MEMORY.md. Never write a secret (a key, token, password or connection string) into a note. Update an existing note rather than adding a twin, and delete notes proven wrong. Then, when the memory folder is its own git repo, commit it by the rules of `pvc-git-commit-message-local`. Closing the set is the request to commit, so take that skill's commit branch and do not stop at the message. Give every git call of this commit the folder, as in `git -C <folder> status`, `git -C <folder> add` and `git -C <folder> commit`: the memory folder sits outside the project, a `cd` into it does not carry over to the next call, and a plain git call would then run in the project and could commit its staged changes under the memory message. To find out whether it is its own repo, look for a `.git` entry, a folder or a file, inside the memory folder: with none, it is not its own repo, and no git call runs. With one, run `git -C <folder> rev-parse --show-toplevel`: it is its own repo when the answer is that folder; compare the two with every backslash read as a slash and the drive letter in any case. An answer with a parent folder, or the git message `not a git repository`, means it is not. Not its own repo: write "Memory: N notes updated (<folder>), folder is not a git repo, no commit" and go on. Any other git error goes into the Memory block as an error, with no memory commit. Nothing new: write "Memory: notes already current (<folder>)" and still check for uncommitted edits made earlier in the session.
3. **Commit the project.** Follow `pvc-git-commit-message-local` end to end in the project. Closing the set is the request to commit, so take that skill's commit branch: read the tree, pick the bump, write the PVC message (no quotes, no backticks, blank line after the headline), stage the named paths for this set including the CLAUDE.md and LABS.md changes (none when only the already staged changes go in, by the user's choice, or by that skill's default when no question can be asked; the Commit block then names the lab-note files left out), commit, report the short hash. Clean tree: print its refusal line and go on.
4. **Hand over /compact.** End with two lines. The first is a ready-to-copy compact line built from the set: `/compact Set <vX.Y.Z> Closed (<Topic>), Keep Open Items, Paths, Hashes`, in Title Case like a commit headline. The version comes from the commit of step 3, or else from the last commit whose headline starts with vX.Y.Z (a clean tree, a failed commit). When no commit has one (a new repo, a first commit that failed, a history with no PVC headline), leave the version out, `/compact Set Closed (<Topic>), Keep Open Items, Paths, Hashes`, and take the topic from the work of the set. The topic is two to four words that say what the set was about, taken from the headline of that same commit (`Photo Backup Set`, `Worker Retry Loop`), or from the work of the set when the commit of step 3 failed. The keep clause tells the summarizer to keep the open items, the exact paths and the commit hashes. No date in the line. Keep the whole line under 80 characters: the fixed words take about 62, so the topic gets about 17, and when the line runs long, shorten the topic, never the keep clause. The second line is `Then say what you want next.`

## What To Print

One shape: three labelled blocks, then the two hand-over lines. Keep each block to two or three lines. A skipped part keeps its label and one line of reason.

```
CLAUDE.md: 2 lab notes added, 2 rotated to LABS.md, 1 pointer line added.
Memory: 3 notes updated, 1 added (~/.claude/projects/-srv-my-app/memory); committed 889d5fa v0.0.2 - Added the Backup Drive Note
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
Memory: notes already current (~/.claude/projects/-srv-my-app/memory), nothing to commit.
Commit: nothing to commit, working tree is clean.
/compact Set v0.3.1 Closed (Worker Retry Loop), Keep Open Items, Paths, Hashes
Then say what you want next.
```

## Resilience

- **Memory folder missing (auto memory on):** when the search of Where Things Live finds no folder of this project under `<config dir>/projects`, create it, write the notes and a MEMORY.md index, say so in the Memory block, skip the memory commit, continue with the project commit.
- **CLAUDE_CONFIG_DIR unset while several config dirs exist:** use `~/.claude`, since that is what a plain `claude` call uses, and print the path so a wrong config dir shows at once.
- **Commit fails (hook, lock, nothing staged) in either repo:** show the git error, leave the tree as it is, still print the two hand-over lines so the user can compact and retry.
- **Re-run on the same set:** CLAUDE.md gets no duplicate notes (check the titles first), memory notes get no twins (check the names first), both commits refuse on a clean tree. Safe to call twice.
