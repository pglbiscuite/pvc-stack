# Requirements: pvc-git-commit-message-local

What a fresh machine needs before this skill runs. Tick each box once it is on the machine.

## Required

- [ ] **git** (the skill reads git status, git diff and git log, then runs git commit)
  Check `git --version`, install https://git-scm.com/downloads. On Windows that same installer gives Claude Code the Bash shell it commits through
- [ ] **A git repository in the project you open** (the skill commits into an existing repo, it never creates one)
  Check `git status`, start one with `git init`
- [ ] **A git identity** (git refuses the first commit without one)
  Check `git config user.name`. When it prints nothing, set both values: `git config --global user.name "Your Name"` and `git config --global user.email "your mail address"`, each with your own value in the quotes

Nothing else to install. Claude Code supplies the tools the skill uses.
