ARG version=3.11

FROM python:$version-slim as builder

ENV PYTHONDONTWRITEBYTECODE=1 \
  PYTHONUNBUFFERED=1 \
  PATH=/root/.local/bin:$PATH \
  PIP_NO_CACHE_DIR=1 \
  PIP_DISABLE_PIP_VERSION_CHECK=1 \
  POETRY_VIRTUALENVS_IN_PROJECT=1

WORKDIR /app

COPY pyproject.toml poetry.lock ./

RUN pip install poetry
RUN poetry install --no-root

ARG version
FROM python:$version-slim as runtime

ENV VIRTUAL_ENV=/app/.venv \
  PATH=/app/.venv/bin:$PATH \
  USER_NAME=hoge_user

COPY --from=builder $VIRTUAL_ENV $VIRTUAL_ENV

WORKDIR /app
COPY . /app

RUN useradd -r -u 1000 $USER_NAME
RUN chown -R $USER_NAME:$USER_NAME /app

USER $USER_NAME
