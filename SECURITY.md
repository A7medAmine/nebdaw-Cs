# Security policy

nebdaw's scripts install software and change PATH on students' computers, so we take security problems seriously.

## Reporting a vulnerability

**Do not open a public issue for security problems.**

Report them privately through GitHub instead: go to the repository's **Security** tab and click **Report a vulnerability**. Include:

- what the problem is and which file it is in;
- how someone could trigger it;
- which systems are affected (Windows, Linux, macOS).

You should get a reply within a week. Once a fix is released, you'll be credited in the release notes unless you'd rather stay anonymous.

## What counts

Examples of problems we want to hear about:

- the scripts downloading or running anything from an untrusted source;
- a way to make the scripts run code the user didn't intend;
- the scripts damaging the user's existing PATH or system settings;
- personal data (names, emails, tokens, hosts) left in `python-dev.code-profile`.

## Supported versions

Only the latest version on the `main` branch is supported.
