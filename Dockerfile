# ============================================
# Stage 1: Builder
# Purpose: Install dependencies and train the ML model
# ============================================
FROM python:3.11-slim AS builder

# Set the working directory for the build process
WORKDIR /build

# Avoid Python cache files and reduce noisy stdout buffering.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Install system-level build tools (required for some Python C-extensions)
# Clean up apt cache to keep the builder layer lean
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential && \
    rm -rf /var/lib/apt/lists/*

# Copy requirements first to leverage Docker layer caching
# This ensures pip install only runs if requirements.txt changes
COPY requirements.txt .

# Install dependencies to a local user directory
# --no-cache-dir reduces image size; --user avoids permission issues
RUN pip install --user --no-cache-dir -r requirements.txt

# Copy the rest of the application source code
COPY . .

# Execute the training script during the build process
# This generates 'app/model.joblib' inside the builder stage
RUN python scripts/train_model.py


# ============================================
# Stage 2: Runtime
# Purpose: Final production-ready inference image
# ============================================
FROM python:3.11-slim AS runtime

# Set the application directory
WORKDIR /app

# Runtime settings and shared library dependency for scikit-learn.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/home/appuser/.local/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgomp1 && \
    rm -rf /var/lib/apt/lists/*

# Security Best Practice: Create a non-root user to run the application
# This follows the principle of least privilege
RUN useradd --create-home --shell /bin/bash appuser
USER appuser

# Copy only the installed Python packages from the builder stage
# This step excludes bulky build tools (gcc, etc.) from the final image
COPY --from=builder /root/.local /home/appuser/.local

# Copy the app directory (containing main.py and the newly trained model.joblib)
# Ensure the non-root user owns these files
COPY --from=builder --chown=appuser:appuser /build/app /app

# Expose the port FastAPI will listen on
EXPOSE 8000

# Health check to ensure the service is responding
# Useful for container orchestration and CI/CD validation
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1

# Start the production server using Uvicorn
# 'main:app' assumes main.py is in the root of the /app directory
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
