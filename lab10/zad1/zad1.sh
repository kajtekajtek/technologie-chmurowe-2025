#!/bin/sh
# usage: ./zad3.sh [--clean]

set -euo pipefail

CLEAN=false

if [ "${1:-}" = "--clean" ]; then
    CLEAN=true
fi

IMAGE_A="microservice-a:v1.0"
IMAGE_B="microservice-b:v1.0"
CLUSTER="microcluster"
KIND_BIN="$(go env GOPATH)/bin/kind"

cleanup() {
    echo "=== cleaning up... ==="
    $KIND_BIN delete cluster --name "$CLUSTER" || true
    docker rmi "${IMAGE_A}" "${IMAGE_B}" || true
    rm -rf microservice_a microservice_b k8s-manifests || true
}
[ "$CLEAN" = true ] && trap cleanup EXIT

echo "=== creating cluster... ==="
$KIND_BIN create cluster --name "$CLUSTER"

echo "=== creating microservice_b... ==="
mkdir -p microservice_b
cat > microservice_b/app.py <<EOF
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/hello')
def hello():
    return jsonify(message="Hello from microservice_b")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
cat > microservice_b/requirements.txt <<EOF
flask
EOF
cat > microservice_b/Dockerfile <<EOF
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

echo "=== creating microservice_a... ==="
mkdir -p microservice_a
cat > microservice_a/app.py <<EOF
from flask import Flask, jsonify
import requests
app = Flask(__name__)

@app.route('/call-b')
def call_b():
    resp = requests.get('http://microservice-b-svc:5000/hello')
    data = resp.json()
    return jsonify(from_b=data)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
cat > microservice_a/requirements.txt <<EOF
flask
requests
EOF
cat > microservice_a/Dockerfile <<EOF
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

echo "=== building and loading images... ==="
for srv in a b; do
  IMAGE_VAR=IMAGE_${srv^^}
  IMAGE_VAL=${!IMAGE_VAR}
  docker build -t "$IMAGE_VAL" ./microservice_${srv}
  $KIND_BIN load docker-image "$IMAGE_VAL" --name "$CLUSTER"
done

echo "=== generating manifests... ==="
mkdir -p k8s-manifests
cat > k8s-manifests/msb-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microservice-b
spec:
  replicas: 1
  selector:
    matchLabels:
      app: microservice-b
  template:
    metadata:
      labels:
        app: microservice-b
    spec:
      containers:
      - name: msb
        image: ${IMAGE_B}
        ports:
        - containerPort: 5000
EOF
cat > k8s-manifests/msb-svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: microservice-b-svc
spec:
  type: ClusterIP
  selector:
    app: microservice-b
  ports:
  - port: 5000
    targetPort: 5000
EOF

cat > k8s-manifests/msa-deploy.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microservice-a
spec:
  replicas: 1
  selector:
    matchLabels:
      app: microservice-a
  template:
    metadata:
      labels:
        app: microservice-a
    spec:
      containers:
      - name: msa
        image: ${IMAGE_A}
        ports:
        - containerPort: 5000
        env:
        - name: B_URL
          value: "http://microservice-b-svc:5000/hello"
EOF
cat > k8s-manifests/msa-svc.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: microservice-a-lb
spec:
  type: LoadBalancer
  selector:
    app: microservice-a
  ports:
  - port: 80
    targetPort: 5000
EOF

echo "=== deploying manifests... ==="
kubectl apply -f k8s-manifests/
kubectl rollout status deployment/microservice-b --timeout=60s
kubectl rollout status deployment/microservice-a --timeout=60s
kubectl get all

kubectl port-forward svc/microservice-a-lb 8080:80

echo "=== script finished... ==="
