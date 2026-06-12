"""A minimal containerized service used as the deploy target for the IaC.

Exposes the endpoints an ECS/ALB health check and a monitoring dashboard need:
a liveness probe, a readiness probe, and a trivial work endpoint.
"""

from __future__ import annotations

import os
import socket

from fastapi import FastAPI

app = FastAPI(title="cloud-deploy-iac demo service", version="1.0.0")

COMMIT = os.getenv("GIT_COMMIT", "dev")


@app.get("/health")
def health() -> dict:
    """ALB / ECS health check target."""
    return {"status": "ok", "host": socket.gethostname(), "commit": COMMIT}


@app.get("/ready")
def ready() -> dict:
    return {"ready": True}


@app.get("/")
def root() -> dict:
    return {
        "service": "cloud-deploy-iac demo",
        "message": "Deployed to AWS ECS Fargate via Terraform + GitHub Actions.",
        "commit": COMMIT,
    }
