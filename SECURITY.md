# Security Policy

This is an **unofficial, community-maintained Linux port** of the Kyber
Launcher. It only covers the Linux loading/injection layer and packaging.
The core `Kyber.dll` is an upstream, closed-source component and is **not**
part of this project's source.

## Supported Versions

Only the latest released version receives security fixes. Because this is a
beta-stage port, older releases are not maintained - please update before
reporting an issue.

| Version        | Supported          |
| -------------- | ------------------ |
| Latest release | :white_check_mark: |
| Older releases | :x:                |

## Scope

Please report issues that affect the **Linux port itself**, for example:

- The AppImage build, packaging (AUR) or update mechanism
- The Wine/Proton loading and DLL injection layer
- Bundled scripts and configuration shipped by this project

**Out of scope:** vulnerabilities in `Kyber.dll` or the Kyber service itself.
Those concern the upstream Kyber project and cannot be fixed here - please
report them to the official Kyber team instead.

## Reporting a Vulnerability

Please do **not** open a public issue for security problems.

Use GitHub's **private vulnerability reporting** for this repository:
Security → Report a vulnerability.

You can expect an initial response within a few days. As this is a spare-time,
unofficial project, fix timelines depend on severity and available time. I'll
keep you updated on whether a report is accepted, and credit you if you wish.
