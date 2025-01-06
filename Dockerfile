ARG PYTHON_VERSION=3.13 \
  POETRY_VERSION=1.8.5

FROM python:${PYTHON_VERSION}-slim AS base

ARG POETRY_VERSION
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  curl \
  && rm -rf /var/lib/apt/lists/* \
  && pip install "poetry==${POETRY_VERSION}"

ENV \
  PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PIP_NO_CACHE_DIR=off \
  PIP_DISABLE_PIP_VERSION_CHECK=on \
  VIRTUAL_ENV="/.venv" \
  PATH=${VIRTUAL_ENV}/bin:$PATH \
  POETRY_VIRTUALENVS_CREATE=false \
  POETRY_VIRTUALENVS_IN_PROJECT=false \
  POETRY_NO_INTERACTION=1 \
  POETRY_VERSION=${POETRY_VERSION}

COPY pyproject.toml poetry.lock ./

RUN python -m venv ${VIRTUAL_ENV} \
  && . ${VIRTUAL_ENV}/bin/activate \
  && poetry install --no-root

FROM base AS builder
WORKDIR /app

COPY . .
RUN poetry install --no-dev
RUN poetry build -f wheel

FROM base AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PATH="/app/.venv/bin:$PATH"

WORKDIR /app

COPY --from=builder app/dist/*.whl ./
COPY dj_to/ app/dj_to/

RUN pip install --no-cache-dir *.whl \
  && rm -rf *.whl

WORKDIR /app/dj_to
