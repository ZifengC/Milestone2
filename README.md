# Iris Prediction Service (Milestone 2)

FastAPI service for Iris class prediction with:
- Multi-stage Docker build
- GitHub Actions CI/CD
- Push to Google Artifact Registry (GCP)

## Project Structure

- `app/main.py`: FastAPI app (`/health`, `/predict`)
- `scripts/train_model.py`: trains and writes `app/model.joblib`
- `Dockerfile`: multi-stage image (builder + runtime)
- `.github/workflows/build.yml`: test, smoke test, and push pipeline
- `tests/test_app.py`: API tests

## API

- `GET /health` -> `{"status":"healthy"}`
- `POST /predict` -> `{"prediction": <0|1|2>}`

Example request:

```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```

## Local Development

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install pytest pytest-cov httpx
pytest tests -v --cov=app --cov-report=term-missing
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Docker

Build:

```bash
docker build -t iris-prediction:local .
```

Run:

```bash
docker run --rm -p 8000:8000 iris-prediction:local
```

Health check:

```bash
curl -fsS http://127.0.0.1:8000/health
```

## CI/CD Pipeline

Workflow file: `.github/workflows/build.yml`

Jobs:
1. `test`: install deps + run pytest
2. `docker-smoke-test`: build image, start container, verify `/health`
3. `build-and-push`: authenticate to GCP, build/push image to Artifact Registry

## GitHub Configuration for GCP

### Secrets

- `GCP_SA_KEY`: service account JSON key used by:
  - `credentials_json: ${{ secrets.GCP_SA_KEY }}`

### Repository Variables

- `GCP_REGISTRY_HOST` (example: `us-central1-docker.pkg.dev`)
- `GCP_PROJECT_ID`
- `GCP_ARTIFACT_REPO`

Final pushed image format:

`$GCP_REGISTRY_HOST/$GCP_PROJECT_ID/$GCP_ARTIFACT_REPO/iris-prediction:<tag>`

## Release Tags

Push a version tag to trigger release-style image tags:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Security/Quality Notes

- Runtime container runs as non-root user `appuser`
- Multi-stage build excludes build toolchain from runtime
- Docker build context is reduced via `.dockerignore`
