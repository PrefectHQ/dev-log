+++
title = "LLM assisted accountability"
date = "2025-08-16T10:43:06-05:00"
tags = ['meta', 'ai']
description = "I often forget to write, so here's how I'll keep myself accountable to writing a dev log entry every week."

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

When Nate pitched the idea of starting a dev log, I was immediately on board. I’ve wanted to write more for a while, and sharing the day-to-day work we do in the `prefect` library seemed like a great way to finally get some reps in.  

The problem? I know myself. I’ll start strong and then taper off once “real work” starts crowding out the good intentions. Maintaining an open source library means there’s *always* something else to do.  

So, I built automated acountability: [**roast-bot**](https://github.com/desertaxle/roast-bot).  

If I don’t write a dev log entry in a given week, roast-bot (a Prefect flow, naturally) will scrape my GitHub activity, pick my most questionable merged PR from the last week, and have Claude Code roast it. The result gets pushed straight to `main` and published automatically.

Here’s a taste of what roast-bot comes up with: 

On [a recent bug fix](https://github.com/PrefectHQ/prefect/pull/18679), it didn’t hold back:  

> In a stroke of genius that can only be described as "using the right tool for the job," desertaxle realized they could just use the existing `PrefectServerEventsClient` to emit events server-side. Revolutionary! Who would have thought that using server-side clients for server-side operations would be a good idea?  

And when roasting my [in-memory causal event ordering implementation](https://github.com/PrefectHQ/prefect/pull/18634), it really went for the jugular:  

> Five different dictionaries! Because if you’re going to hold state in memory, you might as well hold *all* the state in memory.  

Now, of course, these roasts miss a lot of context (I had good reasons for my implementation choices), but nuance is not roast-bot’s strong suit.  

The upside for you, the reader, is that there will be at least one dev log post here every week. Ideally it’ll be thoughtful and insightful. If not, you’ll get to watch an LLM tear my code to shreds. Either way, you win.  
