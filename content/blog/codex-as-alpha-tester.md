+++
title = "Codex as alpha tester"
date = "2026-03-01T12:00:00-06:00"
tags = ["ai", "dbt", "testing", "codex"]
description = "I gave my alpha docs to a robot before I gave them to humans. It found 10 issues in an hour."

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

I've been building a new dbt orchestrator for Prefect — one that breaks apart `dbt build` and runs each node (or wave of nodes) as a Prefect task. It's still alpha, and I needed to find some of the obvious bugs and rough edges before I moved on to beta testing.

I had a user-facing guide written and ready to hand to alpha testers. But before I sent it to humans (who have feelings and whose time I respect) I figured I'd give it to a machine first to try and break things.

## The setup

I decided to use Codex because it's deadpan and pedantic, which are attributes that I like in a tester. To keep things low touch, I gave Codex free rein in a Docker Compose sandbox.

The setup was three containers: Codex, a Prefect server, and Postgres. The Codex container started with the following command:

```bash
codex exec --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check - < /workspace/PROMPT.md
```

The `--dangerously-bypass-approvals-and-sandbox` flag is key to me being able to do other stuff while Codex is running on its own for an hour or two. Boy, they sure do make it hard to type that flag out by hand.

The `PROMPT.md` was the same reference guide I wrote for users, with one addition: instead of "follow this guide to set up the orchestrator," the framing was "you are an experienced dbt user doing exploratory testing. Your goal is NOT to verify the happy path. Your goal is to find bugs, rough edges, confusing behaviour, and friction."

I also gave it the full API reference doc and told it to write structured findings: severity, area, what it did, what happened, what it expected.

## What it found

Codex worked through each feature area methodically and produced a structured document with 10 distinct issues. Some were real bugs: error results swallowing the actual dbt error messages, cache expiration not being respected, asset events failing Pydantic validation. Some were friction: cached nodes being indistinguishable from executed ones in the results and models vanishing from output instead of being marked as skipped. All of them were things a real user would have hit, and none of them were things our existing test suite caught.

## What I took away

The bugs have already been fixed or are in-progress, but the more interesting takeaway is about the process.

The guide I gave Codex was the same guide I was going to give to users. By running it through a machine first, I essentially got a pre-flight check on the entire user experience. It was a quick, repeatable way to find out, "does a fresh pair of eyes, following our docs, actually end up in a good place?" The answer was a qualified meh, and now I know what to fix.

This is different from unit tests or integration tests. Those verify that the code does what *I* think it should do. This verified that the code does what an approximation of a user reading our guide would expect it to do. Unit tests are you quizzing yourself with flashcards you wrote. This is handing the textbook to some sand that wizards tricked into thinking and seeing if it passes the exam.

There's also a more pragmatic angle: more and more code is being written by AI agents. If the functionality you build can't successfully be used by an agent following your docs, it's DOA in today's world.

I'll probably do this again before the next alpha goes out. `docker compose up`, boss around some other agents for an hour, and read the findings. Not a bad deal.
