ARG PY_VERSION=3.11
FROM python:${PY_VERSION}
COPY app/ .
RUN pip install --no-cache-dir -r  requirements.txt
CMD ["python", "app.py"]