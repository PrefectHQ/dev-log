+++
title = "Break This Design"
date = "2026-04-19T12:00:00-05:00"
tags = ["ai", "design"]
description = "Codex, heckle me into a good architecture"

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

I recently spent a long session working through a design for a reliability issue in Prefect. Flow runs can get stuck in `PENDING` when a worker claims a run but the execution environment never transitions it to `RUNNING`, which is almost always caused by a worker crashing between claim and launch. Users have been burned by this in ways that quietly erode trust, and we needed a server-side story for detection and recovery. The design itself is kind of interesting, but that's not what I want to write about.

The interesting part was the process. The design got sharper once I started using a coding agent as a design partner.

The obvious temptation is to ask an AI to propose the architecture and then polish what it hands back. I tried a little of that early on, and it produced a plausible first draft, but that plausibility was deceptive. The hard part of technical design isn't writing something that sounds coherent and looks handsome in a Notion Doc, but instead writing something that stays correct under every edge case a production system will actually throw at it. A plausible-but-shallow draft doesn't survive first contact with a reviewer who cares about invariants.

## "Break this design"

So I flipped the framing. Here is a design. Try to break it. Find the edge cases, find the interactions between this rule and that one, and tell me which sentences imply a stronger guarantee than the system can actually offer.

The conversation stopped looking like prose polishing and started looking like an adversarial review. That turned out to be worth a lot.

## What the agent was good at

The agent was genuinely useful for the kind of scrutiny that's easy to hand-wave through when you've been staring at the same design doc for three hours:

- surfacing edge cases I had half-considered and quietly filed away
- catching places where two sections contradicted each other because each made sense on its own
- flagging sentences that sounded like invariants but weren't enforceable
- asking the uncomfortable follow-up question every time I tried to paper something over

One concrete example: the design needs a way for the server to tell workers "this claim is dead, please tear down whatever infrastructure is still attached to it." In the first draft, I specced a generic work-pool queue that could carry *any* worker command. The agent kept poking. What does "any command" mean? Who guarantees delivery? What are the retry semantics? Is this a command bus or a cleanup channel? Eventually it was clear that I was over-engineering for v1 and needed to narrow the design to a cleanup-oriented transport only. This made the semantics more explicit and the design had less surface area to defend.

That pattern repeated all session. Broad concepts got narrowed. Fuzzy semantics got pinned down. Several abstractions that looked elegant in isolation turned out to be promising future maintenance burdens dressed in flowery language. The right move was usually to cut them back to what the system actually had to do.

## What I still had to do myself

The agent was strong at sustained scrutiny. It was not good at owning the product boundary.

It could tell me that a rule was ambiguous. It couldn't tell me whether the resulting tradeoff of simpler semantics versus one more edge case was the right call for Prefect and its users. It could flag that mixed-version rollout had failure modes. It couldn't tell me which of those modes were tolerable during the rollout window and which were hard blockers. Every time a critique landed, I still had to decide: accept, reject, narrow, or refine.

That four-option loop ended up being the most useful interaction pattern of the whole session. We worked one issue at a time. When the conversation started sprawling, the quality dropped fast. Constraining each thread to a single explicit decision kept the design moving instead of drifting.

## Revelling in the pushback

The most valuable moments were the ones where I thought the agent was wrong. A suggestion I disagreed with still forced me to articulate *why* the design could hold under the pressure it was trying to apply, and that exercise uncovered real gaps about as often as the suggestions I accepted. You don't get better at defending a design by only hearing from people (or clankers) who already agree with you.

## Hire a heckler

I'm less interested in AI-generated architecture as a starting point than I was a month ago. I'm more interested in AI as a pressure-testing collaborator that can keep pushing on a design long after I've run out of energy to steelman it myself. The prompt that mattered was not "write this for me" but "find the place where this is weaker than it looks."

None of this is really about AI, though. Reliability work benefits from someone trying to break the design before you ship it. A tool that makes that review loop faster and more patient is useful. A tool that writes the design for you is just a faster way to produce something that hasn't been broken yet.
