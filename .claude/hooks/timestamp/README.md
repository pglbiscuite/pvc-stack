# timestamp

A Claude Code hook that puts the date, the weekday and the time in front of every prompt. Claude then knows what day it is, and how much time passed between two messages.

**Version:** 0.2.0

What Claude gets with each prompt:

```
[Current time: 2026-11-23 (Monday) 10:36]
```

## Why

A session knows the date of its start and nothing after that. In a long session Claude reasons from a stale date. This hook gives it the real time with each message, for about 15 tokens per prompt.

## In This Repo

The hook is on in this repo. The file `.claude/settings.json` holds it, so the hook comes with the `.claude` folder when you copy that folder into a project. There is no script to copy: the hook is one command in a settings file.

## Add It by Hand

Do this when you take only this hook, or when your project has a settings file already. Pick the settings file:

- `.claude/settings.local.json` in a project: for you alone, in that project. Start here
- `.claude/settings.json` in a project: for everyone who works in the repo
- `settings.json` in your user `.claude` folder: for every project on the PC

Add one of the three blocks. When the file has a `hooks` key already, add the entry to its `UserPromptSubmit` list. The change applies to a running session too.

You can also ask Claude to do it: "add the timestamp hook from this README to my local settings file".

### One Line for Every Shell

This is the block of this repo. The one command runs in bash (macOS, Linux, Windows with Git Bash) and in PowerShell (Windows with no Git Bash).

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "echo `# <#` >/dev/null; date \"+[Current time: %Y-%m-%d (%A) %H:%M]\"; exit #> > $null; [string]::Format([cultureinfo]::InvariantCulture, '[Current time: {0:yyyy-MM-dd} ({0:dddd}) {0:HH:mm}]', (Get-Date))"
          }
        ]
      }
    ]
  }
}
```

How the line works: bash runs the `date` part and stops at `exit`, and the rest of the line is a comment for it. PowerShell reads the first part as a comment and runs the `Get-Date` part.

### Bash Only

For macOS, Linux, and Windows with Git Bash.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "date \"+[Current time: %Y-%m-%d (%A) %H:%M]\""
          }
        ]
      }
    ]
  }
}
```

### PowerShell Only

For Windows. The `shell` key tells Claude Code to run the command in PowerShell, also on a PC that has Git Bash.

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "shell": "powershell",
            "command": "[string]::Format([cultureinfo]::InvariantCulture, '[Current time: {0:yyyy-MM-dd} ({0:dddd}) {0:HH:mm}]', (Get-Date))"
          }
        ]
      }
    ]
  }
}
```

In PowerShell the weekday is in English on every PC. In bash it follows the language of the system.

## Check It

Send any prompt and ask Claude what time it is. It answers with the time of your PC.

To test the command alone, run its plain form in your shell. It prints one line in square brackets.

```bash
date "+[Current time: %Y-%m-%d (%A) %H:%M]"
```

```powershell
[string]::Format([cultureinfo]::InvariantCulture, '[Current time: {0:yyyy-MM-dd} ({0:dddd}) {0:HH:mm}]', (Get-Date))
```

Inside a settings file the command is a JSON string, so each `"` of it is written as `\"`.

## Switch It Off

Take the entry out of the settings file. For the hook of this repo, delete the `hooks` block in `.claude/settings.json`.

## License

MIT. The license file is at the root of this repo.
