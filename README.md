# opinionated-charts

Opinionated Helm charts for deploying my apps to Kubernetes — Traefik ingress,
cert-manager, SealedSecrets, and serversideup-style images, set up the way I
think they should be.

This is a **chart monorepo**: each chart lives under `charts/<name>/` and is
versioned independently via its own `Chart.yaml`.

## Charts

| Chart | Purpose | Used by |
|-------|---------|---------|
| [`laravel-app`](charts/laravel-app) | Laravel: web + queue worker + scheduler | budgetbuddy, kwekerijvh |
| [`web-service`](charts/web-service) | Single stateless HTTP service — nginx static/SPA sites and API services (FastAPI/uvicorn, etc.) | portfolio, opruim-coach, budgetbunny-ml |

Frontends and standalone services live in `web-service` — the Laravel chart no
longer bundles a frontend.

## Usage

Each chart is consumed by an app's own per-environment values file (kept with the
app, not in this repo). Point Helm at the chart directory:

```bash
helm upgrade --install my-app ./charts/laravel-app -f values-my-app.yaml
```

See each chart's own `README.md` and `values.yaml` for the knobs it exposes.

Released charts are also published as OCI artifacts to ghcr:

```bash
helm upgrade --install my-app oci://ghcr.io/danielvdspoel/charts/laravel-app -f values-my-app.yaml
```

## CI

- **[Lint](.github/workflows/lint.yml)** runs on every PR and push touching
  `charts/**`: `helm lint` each chart, then renders them (incl. the
  `web-service` examples) and validates the output against the Kubernetes API
  schemas with `kubeconform`.
- **[Release](.github/workflows/release.yml)** runs on push to `main`: for each
  chart whose `version` in `Chart.yaml` isn't already in the registry, it
  packages and `helm push`es it to `oci://ghcr.io/danielvdspoel/charts` and tags
  the commit `<chart>-<version>`. Bumping the chart version is the release
  trigger; unchanged versions are skipped, so it's safe to run every push.

> First publish only: the ghcr packages are created **private**. Make each one
> public under the package settings so `helm` can pull without auth.

