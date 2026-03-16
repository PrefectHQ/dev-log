+++
title = "Your Repo Has New Contributors (Whether You Like It or Not)"
date = "2026-03-15T12:00:00-06:00"
tags = ["ai", "oss", "developer experience"]
description = "AI agents are already contributing to your repo. The question is whether you're giving them good context or bad context."

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

Every open source project is getting AI-assisted contributions now, whether the maintainers like it or not. Someone opens a PR and it's suspiciously well-formatted and has a commit message that reads like it was written by a very polite intern. That's because it was. The intern just happens to run on GPUs. That becomes clear when you leave a comment telling the submitter that approach taken appears correct, but is subtley misguided, and they respond with, "You're absolutely right!"

The quality of those contributions depends almost entirely on the context the AI has. Most repos have a `CONTRIBUTING.md` that tells humans where to find the test suite and how to format commit messages, but most are missing the equivalent for AI agents, and it shows. The agent doesn't know that you migrated away from that pattern three months ago, or that the module it's importing from is deprecated, or that there's a `justfile` recipe for the thing it's trying to do by hand. So it guesses, and you get a PR that's technically functional but wrong in all the ways that require a maintainer to explain the last six months of project history in a review comment.

We ran into this enough that we started creating `AGENTS.md` files throughout the Prefect repo. These are like `CONTRIBUTING.md`, but for AI agents. They describe how the codebase works, what conventions to follow, what not to touch, and where the bodies are buried[^1]. We place them strategically at different levels of the directory tree so an agent working in `src/prefect/events/` gets guidance specific to the eventing system without having to digest the entire project's worth of context.

This worked well until it didn't.

The problem is the same one that plagues every piece of documentation ever written: it goes stale. Code changes every day. Someone renames a module, removes a pattern, or introduces a new convention, and the `AGENTS.md` file that references the old way is now actively misleading. Stale human docs are annoying; stale agent docs are worse because the agent won't push back. It'll follow the outdated instructions faithfully and produce a confidently wrong PR. Then a maintainer has to spend time reviewing something that was doomed from the start, which is the exact time sink we were trying to avoid.

So we did what any reasonable team would do: we made the computer check its own homework.

We built a [skill](https://github.com/PrefectHQ/prefect/pull/21010) for Claude Code that analyzes code changes on a branch and detects when `AGENTS.md` files have drifted out of sync with the code they describe. It checks a few things:

- **Accuracy**: do the patterns and files referenced in the guidance still exist in the code? If an `AGENTS.md` says "always use `TaskRunRecorder` for event processing" and that class got renamed last Tuesday, that's a problem.
- **Signal density**: is the guidance actually useful, or is it restating things that are obvious from the code itself? Noise in agent docs is arguably worse than no docs at all because it eats context window.
- **Invariant correctness**: are the rules still true? If the doc says "never import directly from `_internal`" but three modules now do exactly that, either the rule or the code needs to change.

We also wrapped this in a [GitHub Actions workflow](https://github.com/PrefectHQ/prefect/pull/21076) so it runs automatically. When code changes cause `AGENTS.md` files to drift, the workflow opens a PR with the updates. No human has to remember to do it, no staleness builds up silently, and the repo keeps its own onboarding docs current.

The broader point here isn't really about `AGENTS.md` files specifically. It's that AI agents are a new class of contributor to your project, and like any contributor, they do better work when they have good onboarding material. The difference is that human contributors can ask questions in Slack when the docs are wrong. Agents just do the wrong thing and submit a PR.

If you maintain an open source project, the move is to treat AI onboarding docs the way you treat code: something that has to stay in sync, gets tested, and has automation to catch drift. Static markdown files full of guidance that nobody updates are just tech debt with a `.md` extension.

We're still iterating on this. The staleness checker is new and I'm sure it'll have its own rough edges. But the alternative of hoping that the context files stay accurate through sheer willpower has a pretty well-documented success rate hovering just above the floor, so I'll take the robot over wishful thinking.

[^1]: Figuratively. Although if you've seen our git history, it's an archaeologist's dreams.
