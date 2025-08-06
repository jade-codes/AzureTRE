ARG API_VERSION
ARG BUILD_DATE

FROM mcr.microsoft.com/azurelinux/base/python:3 AS base

RUN mkdir /staging

COPY requirements.txt /.
RUN pip3 install --no-cache-dir --root-user-action ignore --root /staging --requirement requirements.txt
RUN pip3 install --no-cache-dir --root-user-action ignore --requirement requirements.txt

FROM base AS test
COPY requirements-dev.txt /.
RUN pip3 install --no-cache-dir -r requirements-dev.txt
COPY . /api
WORKDIR /api
RUN ./run_tests_and_exit_succesfully.sh


FROM scratch AS test-results
COPY --from=test /test-results/* /.


FROM mcr.microsoft.com/azurelinux/distroless/python:3-nonroot AS runtime
ARG API_VERSION
ARG BUILD_DATE

LABEL org.opencontainers.image.authors="Microsoft ISE" \
      org.label-schema.build-date="${BUILD_DATE}"

COPY --from=base --chown=root:root /staging/ /
COPY . /api
WORKDIR /api
USER 65532:65532

CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:8000", "-k", "uvicorn.workers.UvicornWorker","--timeout", "60", "--workers", "5"]
