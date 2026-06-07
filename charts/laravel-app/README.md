# laravel-app

Opinionated Helm chart for deploying Laravel apps to Kubernetes. Designed
around [serversideup/php](https://serversideup.net/open-source/docker-php/)
images and a Traefik + cert-manager + CNPG + SealedSecrets stack.

## What it ships

- **web** Deployment — HTTP-serving Laravel pod with HTTP probes against
  Laravel's `/up` healthcheck, optional HPA, PDB, anti-affinity via topology
  spread, and a `preStop` sleep so Traefik can deregister the endpoint cleanly
  on rollouts.
- **worker** Deployment — long-running `queue:work` with a `pgrep` liveness
  probe and a tunable termination grace period that defaults to 120s so
  long jobs aren't SIGKILL'd mid-rollout.
- **scheduler** Deployment — long-running `schedule:work` (not a CronJob,
  because spawning a fresh pod every minute just to run a 100ms scheduler
  tick is wasteful). Hard-pinned to `replicas: 1` with `strategy: Recreate`.
- **frontend** Deployment (optional) — separate static SPA deployment for
  apps with a Vue/React/etc. frontend served by nginx.
- **Ingress + Traefik Middleware** — multi-host TLS, optional `www.* → non-www`
  redirect.
- **ConfigMap** with checksum-annotation rolling on change.
- **ServiceAccount** with `automountServiceAccountToken: false` by default.
- **PodDisruptionBudget** when replicas > 1.
- **HorizontalPodAutoscaler** (optional, off by default).

## What it does NOT ship

- **Secrets**: this chart references existing Secrets by name only. Use
  [SealedSecrets](https://github.com/bitnami-labs/sealed-secrets) or
  external-secrets to manage them out-of-band.
- **Database**: external Postgres assumed (we use [CNPG](https://cloudnative-pg.io/)
  in a separate `postgres` namespace; the `Database` CR is applied alongside,
  not by this chart).
- **Redis**: external assumed.
- **Migrations**: handled by the serversideup image's
  `AUTORUN_LARAVEL_MIGRATION` env var (set `--isolated` semantics via
  `AUTORUN_LARAVEL_MIGRATION_ISOLATED=true` if running >1 web replica).

## Install

```bash
helm install <release> oci://ghcr.io/<owner>/charts/laravel-app \
  --namespace <namespace> --create-namespace \
  -f values.yaml
```

Or directly from the source repo:

```bash
git clone https://github.com/<owner>/helm-laravel-app.git
helm install <release> ./helm-laravel-app/helm \
  --namespace <namespace> --create-namespace \
  -f values.yaml
```

See `../helm-example/` in this repo for full usage examples.

## Values

See [`values.yaml`](./values.yaml) — every key is documented inline.

The two most-used groups:

- `image.repository` / `image.tag` — leave `tag` empty to default to
  `Chart.AppVersion`. Bump the chart version per release for a clean
  audit trail.
- `web` / `worker` / `scheduler` / `frontend` — per-role config. Each
  role inherits `image`, `podSecurityContext`, `containerSecurityContext`,
  `imagePullSecrets`, and the shared ConfigMap automatically.

## Compatibility

- Kubernetes 1.25+ (uses `policy/v1` PDB, `autoscaling/v2` HPA).
- Helm 3.10+.
- Traefik v2/v3 for the optional `redirect-www` Middleware. Other ingress
  controllers work fine if you set `ingress.redirectWwwToNonWww: false`
  and override `ingress.className`.
