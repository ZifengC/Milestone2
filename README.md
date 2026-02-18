# Iris Prediction Service (Milestone 2)

[![CI/CD Pipeline](https://github.com/<OWNER>/<REPO>/actions/workflows/build.yml/badge.svg)](https://github.com/<OWNER>/<REPO>/actions/workflows/build.yml)

Production-style ML inference service for Iris class prediction with:
- Multi-stage Docker build
- Automated GitHub Actions CI/CD (test, build, publish)
- Image publishing to container registry with semantic tags

Replace `<OWNER>/<REPO>` in the badge URL after pushing to your GitHub repository.

## Deliverables Mapping (Milestone 2)

1. `Dockerfile`: multi-stage image with builder and minimal runtime stages
2. `app/`: inference service + model artifact
3. `docker-compose.yaml` (optional): not included
4. Registry verification: perform push and capture screenshot/link from registry
5. `.github/workflows/build.yml`: CI pipeline for test/build/push
6. `README.md`: CI badge + image run instructions + quick start
7. `tests/test_app.py`: endpoint and error-handling tests
8. `RUNBOOK.md`: operations runbook for reproducibility, optimization, security, CI/CD, versioning, troubleshooting

## API

- `GET /health` -> `{"status":"healthy"}`
- `POST /predict` -> `{"prediction": <0|1|2>}`

Example:

```bash
curl -X POST http://127.0.0.1:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"sepal_length":5.1,"sepal_width":3.5,"petal_length":1.4,"petal_width":0.2}'
```

## Quick Start (Local Development)

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install pytest pytest-cov httpx
pytest tests -v --cov=app --cov-report=term-missing
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## Pull and Run Published Image

Set your registry coordinates:

```bash
export REGISTRY_HOST=<registry-host>
export PROJECT_ID=<project-id>
export REPOSITORY=<repo-name>
export IMAGE_NAME=iris-prediction
export TAG=v1.0.0
```

Pull and run:

```bash
docker pull $REGISTRY_HOST/$PROJECT_ID/$REPOSITORY/$IMAGE_NAME:$TAG
docker run --rm -p 8000:8000 $REGISTRY_HOST/$PROJECT_ID/$REPOSITORY/$IMAGE_NAME:$TAG
```

Smoke test:

```bash
curl -fsS http://127.0.0.1:8000/health
```

## Registry Verification

Successful image push to registry (example evidence):

![Registry verification screenshot](figure/Screenshot1.png)

## Build and Run Locally with Docker

```bash
docker build -t iris-prediction:local .
docker run --rm -p 8000:8000 iris-prediction:local
```

## CI/CD Summary

Workflow file: `.github/workflows/build.yml`

- `test`: runs `pytest`
- `docker-smoke-test`: builds image and verifies `/health`
- `build-and-push`: authenticates to registry and publishes image tags

## Semantic Versioning

Use `vX.Y.Z` tags for release images:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Security and Reproducibility Notes

- Runtime image runs as non-root user
- Multi-stage build reduces attack surface
- Dependency versions are pinned in `requirements.txt`
- Build context is minimized with `.dockerignore`
