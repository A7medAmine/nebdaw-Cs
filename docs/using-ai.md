# Coding with an AI assistant

AI assistants such as GitHub Copilot, ChatGPT, Claude, Gemini and Cursor can explain errors, review your code and help you learn faster. They can also stop you learning if you let them write everything for you. This guide covers both sides.

## Contents

1. [Pick an assistant](#1-pick-an-assistant)
2. [Use it inside VS Code](#2-use-it-inside-vs-code)
3. [Fix a setup problem with AI](#3-fix-a-setup-problem-with-ai)
4. [Ask good questions](#4-ask-good-questions)
5. [Learn with it, don't copy from it](#5-learn-with-it-dont-copy-from-it)
6. [Stay safe](#6-stay-safe)
7. [Contributing to nebdaw with an AI agent](#7-contributing-to-nebdaw-with-an-ai-agent)

## 1. Pick an assistant

| Kind | Examples | Good for |
|---|---|---|
| Chat in the browser | ChatGPT, Claude, Gemini | Explaining an error, a concept or a piece of code |
| In the editor | GitHub Copilot (VS Code) | Suggestions while you type, chat about the open file |
| Agent in the terminal or editor | Claude Code, Codex, Copilot agent mode, Cursor | Bigger changes across several files that it runs and tests itself |

**Free for students:** GitHub gives verified students free Copilot through the [GitHub Student Developer Pack](https://education.github.com/pack). Sign up with your university email or a student card. Most chat assistants also have a free tier. Free plans and their limits change often, so check each site.

## 2. Use it inside VS Code

The nebdaw profile doesn't include an AI extension, so you choose your own. For GitHub Copilot:

1. Open the Extensions view (`Ctrl+Shift+X`) and install **GitHub Copilot Chat**.
2. Sign in with your GitHub account when VS Code asks.
3. Open the chat with `Ctrl+Alt+I`. Select some code first to ask about just that code.

Useful habits:

- Type `#file` or drag a file into the chat to give it the right context.
- Select an error in the terminal and ask "explain this error".
- Copilot uses your open files as context. Close the ones that have nothing to do with your question.

## 3. Fix a setup problem with AI

If the setup fails, the log file says exactly what went wrong. Give the AI that, not just "it doesn't work".

1. Open the log:
   - Windows (PowerShell): `notepad $env:TEMP\python-dev-setup.log`
   - Linux / macOS: `cat "${TMPDIR:-/tmp}/python-dev-setup.log"`
2. Remove anything private (your username in paths is usually fine, but passwords and tokens are not).
3. Paste it into the assistant with this prompt:

   > I'm a CS student. I ran the nebdaw setup (https://github.com/A7medAmine/nebdaw-Cs) on **Windows 11** to install Python. It failed at step **[step name from the screen]**. Here is the log. Explain in simple words what went wrong and give me the exact commands to fix it, saying which terminal to run them in.
   >
   > ```
   > (paste the log here)
   > ```

If you use an agent that can read this repository (Claude Code, Copilot, Cursor), ask it to "troubleshoot my nebdaw setup". It will find the troubleshooting guide in `.claude/skills/troubleshoot-setup/` on its own.

## 4. Ask good questions

Answers are only as good as the question. Include:

- **What you're trying to do:** "read numbers from a file and print the average".
- **What happened:** the full error message, copied, not retyped.
- **The code:** the smallest piece that shows the problem.
- **Your level and the limits:** "I'm in first year, we haven't seen classes yet, use only lists and loops".

Bad: "my code doesn't work"

Good:

> I'm a first-year student. This Python function should return the average of a list but I get `ZeroDivisionError: division by zero` when the list is empty. Don't rewrite it. Explain why it fails and give me a hint to fix it myself.
>
> ```python
> def average(xs):
>     return sum(xs) / len(xs)
> ```

## 5. Learn with it, don't copy from it

You won't have the AI in the exam. Use it the way you'd use a patient tutor:

- **Ask for hints, not answers.** "Give me a hint, not the code."
- **Ask it to explain.** "Explain this line by line" or "why is this O(n²)?".
- **Write first, then ask for a review.** "Here is my solution. What would you improve and why?"
- **Check what it says.** AI is often confidently wrong. Run the code and test edge cases (empty list, negative numbers, huge input).
- **Follow your course rules.** Many courses don't allow AI-written code in graded work. If you're not sure, ask your teacher.

A good rule: if you can't explain every line you submit, don't submit it.

## 6. Stay safe

- **Never paste passwords, API keys, tokens or personal data** into an AI chat.
- **Read commands before running them.** This matters most for anything with `sudo`, `rm`, `del`, `Remove-Item`, `format`, `curl ... | bash` or `irm ... | iex`. Ask the AI what a command does if you aren't sure.
- **Only install packages you've heard of.** AI sometimes invents package names, and attackers publish malware under those names. Check the package on https://pypi.org before running `pip install`.
- **Agents can change and delete files.** Commit your work with git before you let an agent edit a project, so you can undo it.

## 7. Contributing to nebdaw with an AI agent

AI-assisted contributions are welcome. This repository is set up for it:

- [`AGENTS.md`](../AGENTS.md) has the project rules. Claude Code, Codex, Copilot, Cursor and Gemini read it automatically.
- [`.claude/skills/`](../.claude/skills/) has step-by-step guides for common tasks: adding a library, editing the setup scripts, updating the VS Code profile and troubleshooting. Claude Code loads them as skills; other agents can be pointed at the files.

You're still the author. Before you open a pull request:

1. Read and understand every changed line.
2. Test it on a real system (a VM or Windows Sandbox is fine).
3. Say in the PR that an AI helped and what you tested.

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the rest.
