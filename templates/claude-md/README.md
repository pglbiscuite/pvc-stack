# claude-md

<p align="center"><img src="assets/claude-md-start.jpg" alt="claude-md" width="360"></p>

> A starter CLAUDE.md of voice rules and chat tone for Claude Code: plain words and no AI tells.

**Version:** 0.1.0

A `CLAUDE.md` to copy into a project. It gives Claude one voice for everything it writes for you: short sentences, plain words, and a list of phrases it must not use. A second part sets how Claude talks to you in chat. Made by Pro Vibe Coding, in use since July 2026.

## What Is in the File

| Part | What it does |
|---|---|
| The Voice | The target: short sentences, plain words, the point said directly |
| Universal AI Slop Filter | Rules that catch the common AI tells, most with words to use in their place |
| Voice Rules (Edit to Taste) | House rules of one voice. Keep them, swap them or cut them |
| Chat Tone | How Claude talks to you in chat: no praise openers, measured and direct |

## Install

1. Copy `CLAUDE.md` from this folder to the root of your project.
2. If the project has a `CLAUDE.md` already, do not copy over it. Paste the parts you want into your file.
3. Start a new Claude Code session. Claude loads the file when a session starts.

To use the rules in every project on your machine, put them in the `CLAUDE.md` of your user `.claude` folder.

## Make It Yours

- Change the first line to the name of your project.
- Go through "Voice Rules (Edit to Taste)". These rules reflect one voice. Keep the ones that fit yours.
- Change the "Chat Tone" part to the way you want Claude to talk to you.
- Add the facts of your project after the rules: what it is, how to run it, what Claude must never do. The skill `pvc-claude-md` in this repo audits that part and keeps it current.

## License

MIT. The license file is at the root of this repo.
