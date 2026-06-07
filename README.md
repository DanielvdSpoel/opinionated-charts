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
