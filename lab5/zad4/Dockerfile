ARG PY_VER=3.11
ARG PORT=8000

FROM alpine:latest

ENV PY_VER ${PY_VER}
ENV PORT ${PORT}

RUN apk update && \
    apk add --no-cache python3 py3-pip && \
    rm -rf /var/cache/apk/*

RUN mkdir -p /data

VOLUME ["/data"]

EXPOSE ${PORT}

WORKDIR /app

CMD python3 -m http.server $PORT