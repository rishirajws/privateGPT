FROM python:3.11.6-slim-bookworm as base

# Install poetry
RUN pip install pipx
RUN python3 -m pipx ensurepath
RUN pipx install poetry
ENV PATH="/root/.local/bin:$PATH"
ENV PATH=".venv/bin/:$PATH"

# https://python-poetry.org/docs/configuration/#virtualenvsin-project
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

FROM base as dependencies
WORKDIR /home/worker/app
COPY pyproject.toml poetry.lock ./

RUN poetry install --with ui

FROM base as app

ENV PYTHONUNBUFFERED=1
ENV PORT=8147
EXPOSE 8147

# Prepare a non-root user
RUN adduser --system worker
WORKDIR /home/worker/app

RUN mkdir local_data; chown worker local_data
RUN mkdir models; chown worker models
COPY --chown=worker --from=dependencies /home/worker/app/.venv/ .venv
COPY --chown=worker private_gpt/ private_gpt
COPY --chown=worker fern/ fern
COPY --chown=worker *.yaml *.md ./
COPY --chown=worker scripts/ scripts

ENV PYTHONPATH="$PYTHONPATH:/private_gpt/"

USER worker
ENTRYPOINT python -m private_gpt
