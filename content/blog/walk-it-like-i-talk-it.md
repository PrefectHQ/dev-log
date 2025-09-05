+++
title = "Walk it like I talk it"
date = "2025-09-05T10:43:06-05:00"
tags = ['oss', 'prefect server', 'HA']
description = "Working towards a high availability Prefect server"

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

<<<<<<< HEAD
<<<<<<< HEAD
One of the most common questions from OSS Prefect users is:
=======
One of the most common questions from users is:
>>>>>>> 16874c9 (walk it like i talk it)
=======
One of the most common questions from OSS Prefect users is:
>>>>>>> 2df0aca (word)

> How do I run open-source Prefect server in a high availability ([HA](https://en.wikipedia.org/wiki/High_availability)) mode?

Historically, it hasn't been directly possible, for a couple reasons:
- in-memory event-bus
- related "singleton server" assumptions (e.g. caching automation objects in memory)

Recently, we've been [working towards](https://github.com/PrefectHQ/prefect/discussions/18150) allowing users to run a setup that you can reasonably call HA, by:
- [implementing a Redis Streams-based messaging implementation](https://github.com/PrefectHQ/prefect/pull/16432)
- [using Postgres Listen/Notify to broadcast events to all server instances](https://github.com/PrefectHQ/prefect/pull/18266)
- unwinding those "singleton server" assumptions

We've had some brave souls test out the new recommended setup, but there have been some rough edges.

So, in the words of the visionary triumvirate known as [Migos](https://www.wikipedia.org/wiki/Migos), one must:

> **Walk it like I talk it**


... that is to say, we must run and use the HA setup that we suggest to others.

We always compulsively test fixes and features against actual prefect servers, but it's been a while since we've made a concerted effort to scale a single server installation. The new and broad interest in HA server configurations has made it a great time to do so!

## Making our test bed before we lay in it

We decided on the following initial setup in GKE:
- 2 replicas of the prefect webserver (i.e. `prefect server start --no-services`)
- 1 instance of the background services (i.e. `prefect server services start`)
- 1 instance of the kubernetes worker (i.e. `prefect worker start --type kubernetes`)
- 1 Google-managed Redis instance
- 1 Google-managed Postgres instance

For the yaml-junkies among us, here are (more or less) the Helm chart configurations we used:

<details>
<summary>Helm chart configuration</summary>

`server.yaml`:
```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: prefect-server
spec:
  interval: 5m
  chart:
    spec:
      chart: prefect-server
      version: "2025.9.5190948" # Pin to specific version
      sourceRef:
        kind: HelmRepository
        name: prefect
        namespace: flux-system
  values:
    global:
      prefect:
        image:
          repository: prefecthq/prefect
          prefectTag: 3.4.17-python3.11-kubernetes
    server:
      replicaCount: 2
      loggingLevel: WARNING
      uiConfig:
        prefectUiApiUrl: http://localhost:4200/api
      resources:
        requests:
          cpu: 500m
          memory: 512Mi
        limits:
          cpu: "1"
          memory: 1Gi
      # Add Redis auth environment variables to server pod
      extraEnvVarsSecret: prefect-redis-env-secret
    migrations:
      enabled: true
    backgroundServices:
      runAsSeparateDeployment: true
      # Use the Redis auth secret for password
      extraEnvVarsSecret: prefect-redis-env-secret
      messaging:
        broker: prefect_redis.messaging
        cache: prefect_redis.messaging
        redis:
          host: <REDIS_HOST_IP>
          port: 6379
          db: 0
          username: default
    # External PostgreSQL (Cloud SQL)
    postgresql:
      enabled: false
    # External Redis (Memorystore)
    redis:
      enabled: false
    # External database connection via secret
    # This secret will be created by SecretProviderClass from GCP Secret Manager
    secret:
      create: false
      name: prefect-db-connection-secret
```
`worker.yaml`:
```yaml
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: prefect-worker
  namespace: <YOUR_NAMESPACE>
spec:
  chart:
    spec:
      chart: prefect-worker
      version: 2025.9.5190948
      sourceRef:
        kind: HelmRepository
        name: prefect
        namespace: flux-system
  driftDetection:
    mode: warn
  install:
    remediation:
      retries: 3
  interval: 5m
  maxHistory: 2
  upgrade:
    remediation:
      retries: 3
  values:
    worker:
      config:
        http2: false
        workPool: <YOUR_WORK_POOL_NAME>
      apiConfig: selfHostedServer
      selfHostedServerApiConfig:
        apiUrl: http://prefect-server.<YOUR_NAMESPACE>.svc.cluster.local:4200/api
      image:
        repository: prefecthq/prefect
        prefectTag: 3.4.17-python3.11-kubernetes
        pullPolicy: Always
      livenessProbe:
        enabled: true
      revisionHistoryLimit: 2
      resources:
        requests:
          memory: 1Gi
        limits:
          memory: 2Gi
```
</details>

You can read more about the helm chart [here](https://github.com/PrefectHQ/prefect-helm.git), and more about Flux [here](https://fluxcd.io/).


Note that as of `prefect==3.4.16`, `prefect server start --no-services` avoids running _any_ services, so as to avoid a bug causing redis connection errors in the server pod. [We still need to audit each background service](https://github.com/PrefectHQ/prefect/issues/18753) independently to ensure they can be horizontally scaled.


There were several PRs that came out of this deployment process:
- [18854](https://github.com/PrefectHQ/prefect/pull/18854)
- [18860](https://github.com/PrefectHQ/prefect/pull/18860)
- [18868](https://github.com/PrefectHQ/prefect/pull/18868)

and in general we expect to feel more of the friction that Prefect Server operators have felt in the past in the coming weeks, as we expand our use of the server for our own needs.

For example, I immediately got very annoyed that I had to click many buttons to pause all schedules for all deployments, so I opened that [#18860](https://github.com/PrefectHQ/prefect/pull/18860) PR above to add an `--all` flag to `prefect deployment schedule pause`.

## Running flows against our new setup

We've got a [nice set of flows](https://github.com/PrefectHQ/canary-flows) deployed and executing successfully via our kubernetes worker, which should help us catch any bugs early using the nighly dev builds and generally act as a canary in the coalmine for issues with HA setups.