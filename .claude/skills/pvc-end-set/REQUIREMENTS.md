# Requirements: pvc-end-set

What a fresh machine needs before this skill runs. Tick each box once it is on the machine.

## Required

- [ ] **The skill `pvc-claude-md`** in the same `.claude/skills/` folder (the lab-note rules and the rotation to `LABS.md`)
  It is in the same repo: `.claude/skills/pvc-claude-md`
- [ ] **The skill `pvc-git-commit-message-local`** in the same `.claude/skills/` folder (the commit format, local only)
  It is in the same repo: `.claude/skills/pvc-git-commit-message-local`
- [ ] **git** (the commit step reads the tree and commits)
  Check `git --version`, install https://git-scm.com/downloads
- [ ] **A git repository in the project you open** (the skill commits into an existing repo, it never creates one)
  Check `git status`, start one with `git init`
- [ ] **A git identity** (git refuses the first commit without one)
  Check `git config user.name`, set it with `git config --global user.name` and `git config --global user.email`

## Optional

- [ ] **A memory folder that is a git repo of its own** (then the memory notes get a commit too)
  The folder is `<config dir>/projects/<slug>/memory`. The skill never runs `git init` there

Nothing else to install. Claude Code supplies the tools the skill uses.
