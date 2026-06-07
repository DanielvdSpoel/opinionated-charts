# web-service

Opinionated Helm chart for a **single stateless HTTP service** on Kubernetes.
One Deployment + Service + Ingress, sharing the same Traefik + cert-manager +
SealedSecrets conventions as [`laravel-app`](../laravel-app).

It deliberately covers two archetypes with one chart, because they differ only
in values:

- **Static / SPA sites** served by nginx — `readOnlyRootFilesystem` with
  emptyDir tmp mounts, `/health` probe, no secrets. (portfolio, opruim-coach)
- **API services** — FastAPI/uvicorn, Node, etc. — env + secrets, `/healthz`
  probe, optional HPA. (the BudgetBunny ML service)

## What it ships

- **Deployment** — single container, `RollingUpdate` with `maxUnavailable: 0`,
  configurable `command`/`args`, probes, resources, securityContext, a
  `preStop` sleep so Traefik can deregister cleanly, and `extraVolumes` /
  `extraVolumeMounts` passthrough (for nginx's writable dirs under a read-only
  root).
- **Service** (ClusterIP by default).
- **Ingress + Traefik Middleware** — multi-host TLS via cert-manager, optional
  `www.* → non-www` redirect.
- **ConfigMap** (`env`) with checksum-annotation rolling on change.
- **ServiceAccount** with `automountServiceAccountToken: false`.
- **HorizontalPodAutoscaler** (optional, off by default).
- **PodDisruptionBudget** when replicas > 1 (or HPA is enabled).

## What it does NOT ship

- **Secrets** — referenced by name only; manage them with SealedSecrets /
  external-secrets out-of-band.
- **Workers / schedulers / queues** — if you need those, you want `laravel-app`
  or a purpose-built chart.

## Install

```bash
helm upgrade --install <release> oci://ghcr.io/danielvdspoel/charts/web-service \
  --namespace <namespace> --create-namespace \
  -f my-values.yaml
```

Or from the source repo:

```bash
helm upgrade --install <release> ./charts/web-service \
  -n <namespace> --create-namespace -f my-values.yaml
```

## Examples

See [`examples/`](./examples):

- [`static-site.yaml`](./examples/static-site.yaml) — nginx static/SPA on 8080
  with a read-only root filesystem.
- [`fastapi.yaml`](./examples/fastapi.yaml) — uvicorn API on 8000 with secrets
  and CPU-based autoscaling.

## Values

See [`values.yaml`](./values.yaml) — every key is documented inline. The knobs
you'll touch most:

- `image.repository` / `image.tag` — leave `tag` empty to track `Chart.AppVersion`.
- `port` — container port (nginx-unprivileged 8080, uvicorn 8000); probes and
  the Service target it automatically.
- `env` / `envFromSecret` — non-secret config (ConfigMap) and existing Secrets.
- `containerSecurityContext.readOnlyRootFilesystem` + `extraVolumes` — flip on
  for static nginx and mount its tmp dirs.
- `ingress.hosts` / `ingress.redirectWwwToNonWww`.
