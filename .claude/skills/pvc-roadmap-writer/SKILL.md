---
name: pvc-roadmap-writer
description: "Writes and updates linear roadmap files: ordered tick-box steps toward one testable finish line. Use when the user says 'make a roadmap', 'roadmap this', 'plan this out in steps', 'turn this idea into a step-by-step plan' or 'what is the path to getting this live? Write it down', when an idea note or voice transcript needs a linear execution file, or when a step in an existing roadmap gets done or decided and the file needs ticking ('tick step 3, we picked the drive today'). Not for daily todo lists, implementation plans with file-level steps, the plan that plan mode proposes, writing specs, or ROADMAP.md phase lists."
metadata:
  author: pvc
  version: "0.2.3"
license: MIT
---

<!-- SPDX-License-Identifier: MIT -->

# pvc-roadmap-writer

Turns an idea, spec, or raw voice note into one linear roadmap file the user can follow without trailing behind, and keeps that file current as steps get done. The format: linear steps, TLDR first, detail under it, tick what is done, one checkable finish statement.

## What This Skill Does Not Do

- Daily task lists or session todos (use the conversation, not a file)
- Full implementation plans with file contents and test commands (use plan mode or a planning skill you have)
- Specs and design documents (write the spec first; this skill can then compress the spec into a roadmap)
- Project ROADMAP.md ledgers that only list phase names (this skill writes execution roadmaps with a finish line)

## The Format (Core Mechanic)

One markdown file. Four parts, in this order, nothing else:

1. **Title + framing.** `# <Thing>, Roadmap`, then 1-3 sentences saying what the thing is and the rule of the file: "Linear. Do the steps in order, tick as you go. The statement at the bottom is the finish line."
2. **Steps.** A `## Steps` section with 5 to 9 numbered checkbox steps. Each step is exactly:
   - `N. [ ] **<TLDR, an action phrase under 10 words>**` on the first line
   - 1-3 plain lines under it: what it means, the one decision inside it, or the concrete output. Never more than 3 lines. Detail beyond that belongs in a linked doc, not the roadmap
   - When the work under a step runs deeper than the headline, checkbox sub-steps under the detail lines: `- [ ] **Nb: <Title>**` (Nb, Nc; the parent line itself is a), each with its own 1-2 detail lines, ticked with dates like any step
3. **Ticks carry dates and decisions.** A finished or decided step becomes `N. [x] **<TLDR>** (done YYYY-MM-DD)` or `(decided YYYY-MM-DD)`, and its detail lines get rewritten to state what WAS done or decided, not what should be. The roadmap is also the record
4. **Finish line.** A `## Done when` section closing the file with ONE testable statement in a blockquote. A stranger must be able to read it and answer yes or no. "The page works well" fails. "A stranger pastes a link, clicks one button, and gets the summary" passes

Hard rules:

- 5 to 9 steps. Fewer than 5 means the idea is one task, not a roadmap; say so and offer to do the task. More than 9 means merge steps or split the project into two roadmaps, ask which
- Steps are ordered by dependency. If two steps could swap places freely, merge them or make the order a decision
- Exactly one decision per decision-step. A step whose TLDR starts with "Decide" contains the options in its detail lines and gets its decision written in when ticked
- Bold titles are Title Case: principal words capitalized; a, an, the, and, or, of, to, in, on, for, with, per stay lowercase unless first; code identifiers and filenames preserved as written. Detail lines stay normal sentences
- One idea per line. Two commitments, conditions, or deliverables never share a line; a parenthetical hiding a second deliverable is a smell, break it into its own sub-step
- Sub-steps exist only for independently tickable work. A step whose content is one plain detail line stays exactly that; never convert description lines into numbered or checkboxed sub-items
- Sub-work found mid-build goes in as a checkbox sub-step under its parent step. Never renumber the roadmap for it
- No em dashes, none of the words that the project's CLAUDE.md bans, hyphen bullets only inside details
- Work already done before the roadmap exists gets pre-ticked with its real date. Never present finished work as pending

## Workflow

1. Gather the source: the idea note, transcript, spec, or the conversation itself. Read it fully
2. Confirm the finish line. If the source contains no testable end state, ask for it in one question before writing anything (Path C below). Everything else can be inferred; the finish line cannot
3. Confirm the save location. Default: `docs/<slug>-roadmap.md` in the current project. If the user names a place, use it. If a roadmap for the same thing already exists at the target, UPDATE it, never write a duplicate beside it
4. Draft the file in the format above. Pre-tick anything already done, with dates
5. Check the draft against the format and the hard rules, then save and give the user the two-line confirmation (Path A)

For an update pass (a step got done or a decision got made): edit the step line to `[x]` with the date, rewrite its detail lines into the record of what happened, adjust the Done when statement only if the decision changed the finish line, and confirm in one line (Path B).

## What To Print

- **Path A, new roadmap:** write the file, then print exactly two lines in chat: the file path, and the count "N steps, M pre-ticked". Do not paste the whole roadmap into chat; the file is the deliverable
- **Path B, update pass:** edit the file, then print one line: which step ticked and what was recorded ("Step 1 ticked: external drive, one dated folder per run")
- **Path C, no finish line:** write nothing. Ask one question: "What is the checkable statement that means this is DONE? Finish the sentence: this is done when a stranger can ___". Resume Path A with the answer

## Worked Examples

### Path A: new roadmap from a rough ask

User: "roadmap the photo backup script we talked about"

File written to `docs/photo-backup-roadmap.md`:

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

Chat output:

```
docs/photo-backup-roadmap.md
5 steps, 1 pre-ticked
```

### Path B: update pass

User: "tick step 2, wrote the script today"

Edit in the file: `2. [ ] **Write backup.py**` becomes `2. [x] **Write backup.py** (done 2026-07-16)` and its three detail lines now read "Written at tools/backup.py.", "Keeps the folder layout." and "Refuses to run when the drive is missing."

Chat output:

```
Step 2 ticked: backup.py written at tools/, drive check included
```

### Path C: no testable finish line

User: "make a roadmap for improving my content game"

Chat output (nothing written):

```
What is the checkable statement that means this is DONE? Finish the sentence: this is done when a stranger can ___
```
