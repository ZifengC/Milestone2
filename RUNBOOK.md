# Operations Runbook

## Service

- Name: `iris-prediction`
- Port: `8000`
- Health endpoint: `GET /health`
- Predict endpoint: `POST /predict`

## Standard Operating Procedures

### 1. Verify Service Health

```bash
curl -i http://127.0.0.1:8000/health
```

Expected:
- HTTP `200`
- Body: `{"status":"healthy"}`

### 2. Build and Run Locally (Docker)

```bash
docker build -t iris-prediction:local .
docker run --rm -d --name iris-local -p 8000:8000 iris-prediction:local
curl -fsS http://127.0.0.1:8000/health
docker logs iris-local
docker rm -f iris-local
```

### 3. Run Test Suite

```bash
pip install -r requirements.txt
pip install pytest pytest-cov httpx
pytest tests -v --cov=app --cov-report=term-missing
```

## CI/CD and Deployment

### Triggering pipeline

- PR to `main`: runs tests + docker smoke test
- Push to `main`: runs full pipeline including push to GAR
- Push tag `v*`: runs full pipeline with semver tags

### Required GitHub config

- Secret: `GCP_SA_KEY`
- Variables:
  - `GCP_REGISTRY_HOST`
  - `GCP_PROJECT_ID`
  - `GCP_ARTIFACT_REPO`

## Incident Playbooks

### Incident A: Tests pass locally but fail in CI

Checks:
1. Confirm Python version parity (CI uses Python `3.11`)
2. Reinstall exact deps from `requirements.txt`
3. Run exact CI command locally:

```bash
pytest tests -v --cov=app --cov-report=term-missing
```

4. Inspect workflow logs for import/path errors

### Incident B: Docker smoke test fails (`/health` not ready)

Checks:
1. Inspect container logs from CI job
2. Validate `app/model.joblib` is generated during build
3. Run locally:

```bash
docker build -t iris-prediction:debug .
docker run --rm -p 8000:8000 iris-prediction:debug
```

4. Hit `/health` manually

### Incident C: Push to Artifact Registry fails (auth/permissions)

Checks:
1. Verify `GCP_SA_KEY` secret exists and is valid JSON
2. Confirm service account roles include Artifact Registry write permissions
3. Verify repo variables (`GCP_REGISTRY_HOST`, `GCP_PROJECT_ID`, `GCP_ARTIFACT_REPO`) are correct
4. Confirm registry hostname format (e.g. `us-central1-docker.pkg.dev`)

## Rollback

Use a previous known-good tag in deployment config, for example:

- `.../iris-prediction:sha-<previous_sha>`
- or `.../iris-prediction:v1.0.0`

Then redeploy the prior image.

## Useful Commands

List local images:

```bash
docker images | grep iris-prediction
```

Check running containers:

```bash
docker ps
```

Tail logs:

```bash
docker logs -f <container_name>
```
