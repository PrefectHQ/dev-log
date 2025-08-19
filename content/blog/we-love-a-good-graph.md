+++
title = "We love a good graph"
date = "2025-08-18T10:43:06-05:00"
tags = ['data platform', 'cli', 'dag']
description = "We're shipping a new Prefect command that moves your entire data platform between environments (and its powered by a DAG 🤫)." 

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

One pretty frequent question we get from users is

> I just got a brand new Prefect Cloud workspace. How do I migrate all my workflows and their config from my proof-of-concept open-source setup?

The historical answer has been

> Here's the prefect client, here are the methods, go write a script 👍 good luck!

... which is obviously not ideal.

So, [we've built](https://github.com/PrefectHQ/prefect/pull/18721) a new Prefect command that does this for you. It's called `prefect transfer` and it will be available in [Prefect 3.4.14](https://github.com/PrefectHQ/prefect/releases). It can transfer your resources between any two profiles, so that means you can migrate:
- from an open-source Prefect server to a Prefect Cloud workspace
- from a Prefect Cloud workspace to an open-source Prefect server
- from an open-source Prefect server to another open-source Prefect server
- from a Prefect Cloud workspace to another Prefect Cloud workspace


How does that happen?

0. In prefect, we have an idea of [profiles](https://docs.prefect.io/v3/concepts/settings-and-profiles/). Profiles are essentially a group of settings that constitute a "Prefect environment". See yours with `vim ~/.prefect/profiles.toml`

1. You identify the source profile, e.g. `local`, that contains the settings required to talk to your environment where all your stuff lives (try `prefect profile ls`)

2. You identify the destination profile (where you want to move your stuff) e.g. `prod`

3. You run `prefect transfer --from local --to prod`

That's it! All of your:
- [Deployments](https://docs.prefect.io/v3/concepts/deployments/)
- [Flows](https://docs.prefect.io/v3/concepts/flows/)
- [Automations](https://docs.prefect.io/v3/concepts/automations/)
- [Work pools](https://docs.prefect.io/v3/concepts/work-pools/)[^1]
- [Variables](https://docs.prefect.io/v3/concepts/variables/)
- [Blocks](https://docs.prefect.io/v3/concepts/blocks/)
- [Concurrency limits](https://docs.prefect.io/v3/concepts/concurrency-limits/)

will now exist in your destination profile. Resources that already exist in the destination are skipped (i.e. the command is idempotent).


## "Cool story bro?"

On its face, this is a pretty pedestrian, quality of life utility - but (as fans of graphs) we think the implementation is pretty interesting!

### Path Dependencies

The key challenge is that certain types of resources cannot exist without other resources. For example, a deployment cannot exist without a flow. A work queue cannot exist without a work pool.

So, when we transfer a resource, we must first ensure that resource's dependencies are transferred first.

This problem might sound familiar to you. It's the same problem that [Kahn's algorithm](https://en.wikipedia.org/wiki/Topological_sorting#Kahn's_algorithm) solves. Here's a [nice video](https://www.youtube.com/watch?v=cIBFEhD77b4) explaining the algorithm.

### The DAG Implementation

As far as our problem is concerned, the basic idea is that each type of resource can discover its own dependencies:

```python
class MigratableDeployment(MigratableResource[DeploymentResponse]):
    async def get_dependencies(self) -> list[MigratableProtocol]:
        deps = []
        # A deployment needs its flow
        if self.source_deployment.flow_id:
            flow = await client.read_flow(self.source_deployment.flow_id)
            deps.append(await MigratableFlow.construct(flow))
        # And its work pool
        if self.source_deployment.work_pool_name:
            pool = await client.read_work_pool(self.source_deployment.work_pool_name)
            deps.append(await MigratableWorkPool.construct(pool))
        return deps
```

We build a DAG from these dependencies. Before execution, we verify it's acyclic using three-color [DFS](https://en.wikipedia.org/wiki/Depth-first_search#Vertex_orderings).

The execution uses self-spawning workers with no central scheduler:

```python
async def worker(nid: uuid.UUID, tg: TaskGroup):
    async with semaphore:  # Respect max_workers limit
        try:
            await process_node(node)
            
            # Check dependents under lock to prevent races
            async with self._lock:
                for dependent in self._status[nid].dependents:
                    if all(self._status[d].state == COMPLETED 
                           for d in dependent.dependencies):
                        tg.start_soon(worker, dependent, tg)
                        
        except (TransferSkipped, Exception) as e:
            # Both intentional skips and failures cascade to descendants
            # TransferSkipped = "already exists", Exception = actual failure
            to_skip = deque([nid])
            while to_skip:
                cur = to_skip.popleft()
                for descendant in self._status[cur].dependents:
                    if descendant.state in {PENDING, READY}:
                        descendant.state = SKIPPED
                        to_skip.append(descendant)
```

The `semaphore` bounds concurrency, the `lock` prevents race conditions when checking dependencies, and the `deque` ensures we skip entire subtrees when failures occur. If a work pool fails, its queues get skipped but unrelated branches continue.

No more scripting around 409s to move your resources around!

Excited to try it? Tried it already and have issues? Let us know on [GitHub](https://github.com/PrefectHQ/prefect/discussions/new/choose)!

[^1]: On Prefect Cloud, the work pools you can create may be limited by your [plan](https://www.prefect.io/pricing).