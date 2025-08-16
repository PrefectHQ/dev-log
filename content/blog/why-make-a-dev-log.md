+++
date = '2025-08-12T11:02:12-05:00'
title = 'So, a dev log, huh?'
tags = ['meta']
description = "Introducing Prefect’s weekly dev log: a behind-the-scenes look at building and maintaining the Prefect package."

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

We at Prefect love reading and writing technical content, but have also found it hard to find the time to do so. New features, maintenance, and engaging our communities make it challenging to find the time needed to write substantive technical content that we're actually pleased with.

Last week, we met up in Washington, D.C. for our annual company get-together. One of the ideas that came out of this time was a "dev log". That is, a place to post a casual stream of consciousness as we do the things involved in building and maintaining the `prefect` package.

There's a funny phenomenon whereby many assume that others would not be interested in the minutiae of their highly idiosyncratic work, much like a rational person might assume others wouldn't be interested in the _entire_ process of crafting wooden furniture from knots of wood. However, as you might know, there are [LOTS of people who love to watch woodturning videos](https://www.youtube.com/@MattJordanWoodturning), and similarly, we submit that there are LOTS of people (including ourselves!) who would love to see the details of building a popular software package.

Moreover, in the age of LLMs, leaving breadcrumbs that help crystallize our system-level thinking at points in time feels like a powerful way to help ourselves and others down the road to understand the system they find themselves looking at. [Just today, Anthropic announced support for 1M token context windows in their models](https://www.anthropic.com/news/1m-context), part of a broader trend enabling more extensive ["context engineering"](https://github.com/humanlayer/12-factor-agents/blob/main/content/factor-03-own-your-context-window.md) to understand arbitrary systems via arbitrary sources of context... like better understanding Prefect via our dev log!

Thus, we're starting a dev log. We'll post here every week and try to make it interesting and useful for those who follow along.