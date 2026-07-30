# Security Policy

## Supported versions

This repository is a **portfolio / demo**. There is no formal support window. Fixes may be applied on a best-effort basis on the default branch.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security-sensitive findings.

Prefer one of:

1. GitHub **Security Advisories** / private vulnerability reporting (if enabled on the repository), or
2. Contact the repository owner via the profile email listed on GitHub.

Include:

- Affected component (Flutter client / NestJS API / storage)
- Steps to reproduce
- Impact assessment
- Any suggested fix (optional)

We will try to acknowledge reports when possible. There is no bug bounty program.

## Please do not

- Include production secrets or personal data in reports
- Demand immediate response for a demo project
- Test against systems you do not own

## Historical note (Supabase)

This project was previously prototyped with Supabase. The **current** default-branch runtime uses Flutter + NestJS + Prisma + PostgreSQL and does **not** use Supabase.

Any old hosted Supabase project from early history should be disabled or have its keys rotated by the owner. Do not treat historical commits as the current architecture.
