+++
title = "More effectively coping with Python's 'type system'"
date = "2025-08-28T10:43:06-05:00"
tags = ['python', 'types', 'pydantic']
description = "Bolting a slightly more sane type system onto python with pydantic"

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

This week, when reviewing [a PR](https://github.com/PrefectHQ/prefect/pull/18801), I observed that [Guidry](https://github.com/chrisguidry) had added a new field to the `RunDeployment` action: `schedule_after`. This new field allows users to schedule a deployment run some fixed time _after_ a [condition](https://docs.prefect.io/concepts/event-triggers/) is met.

Due to _reasons_ orthogonal to this post, we have at least 3 places we need to update schemas when we add a new field like this:
- the object model itself, that is, the `RunDeployment` action model
- the client-side schema for `RunDeployment`
- the server-side schema for `RunDeployment`

It's not important why this is true, but the fact of the matter is that we have 3 separate `BaseModel` subclasses that all will get this new field.

A "delay" must be a positive amount of time, so we want to assert that `schedule_after` must be a non-negative `timedelta`. Therefore, as we are `pydantic` users, the PR included 3 separate but identical `@field_validator` implementations that checked (for each schema) that the value was non-negative.


This could be fine, but I am also haunted by the experience of [migrating from `pydantic` v1 to v2](https://github.com/PrefectHQ/prefect/pull/13574), which included a great deal of moving these functionally identical validators around on multiple schemas.

Therefore, we've begun to use `Annotated` types more often to bind validation logic to field types themselves, so that we don't need to repeat said validation logic on multiple schemas that use those types.

So, that's what I [suggested](https://github.com/PrefectHQ/prefect/pull/18801#discussion_r2304943634) and that's what [we did](https://github.com/PrefectHQ/prefect/pull/18801/commits/f674e22b5559504b3cb4422bee09c1bff86ff4ad)!

It works out really clean (if I do say so myself), and looks like this:

```python
# src/prefect/types/__init__.py

from datetime import timedelta
from typing import Annotated

from pydantic import AfterValidator

def _validate_non_negative_timedelta(v: timedelta) -> timedelta:
    if v < timedelta(seconds=0):
        raise ValueError("timedelta must be non-negative")
    return v

NonNegativeTimedelta = Annotated[
    timedelta,
    AfterValidator(_validate_non_negative_timedelta)
]

# src/prefect/server/schemas/actions.py

from prefect.types import NonNegativeTimedelta

class RunDeployment(BaseModel):
    # ...
    schedule_after: NonNegativeTimedelta
```
... and so on for the rest of the schemas.

The nice things are that:
- you write the validation logic once
- the field types become an interface you can switch out the implementation of
- the field types become self-documenting

Here's a (entirely unedited 🙃) youtube video that I made about this (checks calendar) almost a couple years ago now:

{{< youtube id="rxwkkyQc_MY" >}}






