# Requirements: pvc-end-set

What a fresh machine needs before this skill runs. Tick each box once it is on the machine.

## Required

- [ ] **The skill `pvc-claude-md`**, installed where your sessions load skills: the project's `.claude/skills/` or your personal skills folder (the lab-note rules and the rotation to `LABS.md`)
  It is in the same repo: `.claude/skills/pvc-claude-md`. The folder next to this skill is the simple place
- [ ] **The skill `pvc-git-commit-message-local`**, installed where your sessions load skills, like the one above (the commit format, local only)
  It is in the same repo: `.claude/skills/pvc-git-commit-message-local`. The folder next to this skill is the simple place
- [ ] **git** (the commit step reads the tree and commits)
  Check `git --version`, install https://git-scm.com/downloads
- [ ] **A git repository in the project you open** (the skill commits into an existing repo, it never creates one)
  Check `git status`, start one with `git init`
- [ ] **A git identity** (git refuses the first commit without one)
  Check `git config user.name`. When it prints nothing, set both values: `git config --global user.name "Your Name"` and `git config --global user.email "your mail address"`, each with your own value in the quotes

## Optional

- [ ] **Auto memory on**, the default in a local session (then the skill writes memory notes)
  It is off when `CLAUDE_CODE_DISABLE_AUTO_MEMORY` is `1`, or when `autoMemoryEnabled` is `false` in your settings and that variable is not `0`. A session in a self-hosted environment, other than a Claude Tag session, runs with it off by default. The skill then writes no notes and says so
- [ ] **A memory folder that is a git repo of its own** (then the memory notes get a commit too)
  The folder is the one named in the `autoMemoryDirectory` setting when you set one, `<config dir>/projects/<name>/memory` when `CLAUDE_CONFIG_DIR` and `CLAUDE_CODE_PROJECT_DIR_NAME` are both set, otherwise `<config dir>/projects/<slug>/memory`. The skill never runs `git init` there

Nothing else to install. Claude Code supplies the tools the skill uses.
