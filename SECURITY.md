# Security Policy

## Supported versions

Security fixes are made on the latest commit of the `main` branch. Older commits and forks are not supported.

| Component | Supported |
|---|---|
| `main` (Campus Hub, Android) | Yes |
| `main` (NCV Companion, Flutter and Supabase) | Yes |

## Reporting a vulnerability

**Please do not report security issues in public GitHub issues, pull requests, or discussions.**

Report privately through GitHub: open the **Security** tab and choose **Report a vulnerability**. This sends the report only to the maintainers.

Include:

- The affected component and file or function, if you know it
- Steps to reproduce, or a proof of concept
- The likely impact, for example exposure of student data or bypass of the AI query limit

## What to expect

- We aim to acknowledge a report within 5 working days.
- We will keep you informed while we investigate and fix the issue.
- We will credit you in the release notes, unless you ask us not to.

## Scope notes

- Never include real student data, passwords, or API keys in a report.
- Secrets that were accidentally committed should be rotated immediately, even after they are removed from Git history.
- The AI Tutor's API key lives in Supabase secrets on the server and must never be shipped to the app.
