# simple-row

A status line for Claude Code in one row: the model, the effort level, the context window, your usage limits and the ultracode switch.

**Version:** 0.3.0

```
Opus 5.5 · max | context █░░░░░░░ 17% | week ░░░░░░░░ 0% | 5d 14h | ultracode ON
```

In the terminal the empty part of a bar is a dark slot. This page draws it as `░`.

## What It Shows

| Part | Meaning |
|---|---|
| `Opus 5.5` | The model of the session |
| `max` | The effort level, in a color for each level: `low` green, `medium` yellow, `high` orange, `xhigh` red. The word `max` gets three colors |
| `context` | How full the context window is |
| `5h` | The 5-hour usage limit, then the time left to its reset. It shows when your plan has such a limit |
| `week` | The 7-day usage limit, then the time left to its reset |
| `ultracode` | `ON` in pink or `OFF` in grey, from the `ultracode` key of your settings files |

A bar turns yellow from 60 percent and red from 85 percent.

The colors follow the palette of your terminal. Orange is the one exception: the basic palette has no orange, so the row uses a fixed color of the 256-color table for it.

Claude Code sends the limits for a subscription login only. With an API key the row shows the model and the context window.

In a narrow terminal the bars get shorter, then they go away, then the times go away, then the ultracode part goes away.

## The Ultracode Part

Claude Code does not tell a status line if ultracode is on. So the script reads the key `ultracode` from your settings files. The nearest file wins:

1. `.claude/settings.local.json` in the project
2. `.claude/settings.json` in the project
3. `settings.json` in your user `.claude` folder, or in the folder that `CLAUDE_CONFIG_DIR` names

With `true` the row shows `ON`. With `false` it shows `OFF`. When no file has the key, the row leaves the part out.

One limit: the part shows the setting, and no change made inside a session. After `/effort ultracode` or `/effort ultracode off` the row still shows what the files say.

## What You Need

- Windows with Windows PowerShell 5.1. Every Windows 10 and Windows 11 PC has it. PowerShell 7 works too.
- Claude Code 2.1.119 or later.
- Nothing to install.

On macOS and Linux the script runs only with PowerShell 7 (`pwsh`).

## Install

1. Copy the folder `simple-row` to a place that stays. A good place is `.claude/statusline/simple-row/` in your user folder.
2. Add this block to a Claude Code settings file: `settings.json` in your user `.claude` folder, or `.claude/settings.local.json` in one project. Put in the full path of the script, with forward slashes.

```json
{
  "statusLine": {
    "type": "command",
    "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:/Users/<you>/.claude/statusline/simple-row/statusline.ps1\"",
    "refreshInterval": 60
  }
}
```

3. Start a new session. The row shows after the first reply.

The command works when Claude Code runs it through Git Bash and when it runs it through PowerShell. With PowerShell 7, write `pwsh` in place of `powershell`.

The flag `-ExecutionPolicy Bypass` is needed on most PCs. Windows at its default script policy runs no script file. The flag lets this one script run, for this one start of PowerShell, and it changes no setting of the PC.

## Check It

```
powershell -NoProfile -ExecutionPolicy Bypass -File statusline.ps1 -SelfTest
```

It prints six sample rows, then the effort words in their colors, and ends with `selftest: ok`.

## When the Row Stays Empty

- Claude Code runs a status line only in a folder you trusted. Accept the trust question for the folder.
- The command needs the flag `-ExecutionPolicy Bypass`, as in the block of this page. Without it, Windows at its default script policy runs no script file.
- A company PC can set the script policy by Group Policy. Then the flag does not help, and the row stays empty.
- The path in the settings block needs forward slashes.

## How It Works

Claude Code sends the session as JSON to the script on each update. The script reads the model name, the effort level, `context_window.used_percentage` and `rate_limits`, and prints one line. `refreshInterval` draws the row again each minute, so the time left keeps moving while a session sits idle.

The script never fails a session. On any error it still prints a short row and ends with exit code 0.

The script reads three settings files for the one key `ultracode`. It writes no file and sends nothing.

The file is plain ASCII. The bar cell and the dot are built from character codes, and the output goes out as UTF-8. So Windows PowerShell 5.1 shows them right in every code page.

## License

MIT. The license file is at the root of this repo.
