#!/bin/sh
# usage: ./zad1.sh [--clean]

set -euo pipefail

CLEAN=false

if [ "${1:-}" = "--clean" ]; then
    CLEAN=true
fi

IMAGE_A="microservice-a:v1.0"
IMAGE_B="microservice-b:v1.0"
CLUSTER="microcluster"
MONGO_USER="admin"
MONGO_PASSWORD="admin"
KIND_BIN="$(go env GOPATH)/bin/kind"

cleanup() {
    echo "=== cleaning up... ==="
    $KIND_BIN delete cluster --name "$CLUSTER" || true
    docker rmi "${IMAGE_A}" "${IMAGE_B}" || true
    rm -rf microservice_a microservice_b k8s-manifests || true
}
[ "$CLEAN" = true ] && trap cleanup EXIT

echo "=== creating kind cluster ($CLUSTER)... ==="
$KIND_BIN create cluster --name "$CLUSTER"

echo "=== preparing microservice_b code and Dockerfile... ==="
mkdir -p microservice_b
cat > microservice_b/app.py << 'EOF'
from flask import Flask, jsonify
app = Flask(__name__)

@app.route('/hello')
def hello():
    return jsonify(message="Hello from microservice_b")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > microservice_b/requirements.txt << 'EOF'
flask
EOF

cat > microservice_b/Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

echo "=== preparing microservice_a code and Dockerfile ==="
mkdir -p microservice_a
cat > microservice_a/app.py << 'EOF'
from flask import Flask, jsonify
import requests
app = Flask(__name__)

@app.route('/call-b')
def call_b():
    resp = requests.get('http://microservice-b-svc:5000/hello')
    return jsonify(from_b=resp.json())

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF

cat > microservice_a/requirements.txt << 'EOF'
flask
requests
EOF

cat > microservice_a/Dockerfile << 'EOF'
FROM python:3.9-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py .
EXPOSE 5000
CMD ["python", "app.py"]
EOF

echo "=== building and loading Docker images... ==="
for srv in a b; do
  if [ "$srv" = "a" ]; then
    IMAGE="$IMAGE_A"
    DIR="microservice_a"
  else
    IMAGE="$IMAGE_B"
    DIR="microservice_b"
  fi
  docker build -t "$IMAGE" "$DIR"
  $KIND_BIN load docker-image "$IMAGE" --name "$CLUSTER"
done

echo "=== generating Kubernetes manifests with resource limits and secrets... ==="
mkdir -p k8s-manifests

echo "=== creating MongoDB Secret... ==="
USER_B64=$(echo -n "$MONGO_USER" | base64)
PASS_B64=$(echo -n "$MONGO_PASSWORD" | base64)
cat > k8s-manifests/0-mongo-secret.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
type: Opaque
data:
  mongo-username: $USER_B64
  mongo-password: $PASS_B64
EOF

echo "=== creating PV and PVC for database storage... ==="
cat > k8s-manifests/0-pv-pvc.yaml <<EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: db-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: /mnt/data/db-data
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: db-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
EOF

echo "=== creating MongoDB Pod... ==="
cat > k8s-manifests/2-db-pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: microservice-db
  labels:
    app: microservice-db
spec:
  containers:
  - name: mongo
    image: mongo:4.4
    env:
      - name: MONGO_INITDB_ROOT_USERNAME
        valueFrom:
          secretKeyRef:
            name: mongo-secret
            key: mongo-username
      - name: MONGO_INITDB_ROOT_PASSWORD
        valueFrom:
          secretKeyRef:
            name: mongo-secret
            key: mongo-password
    ports:
      - containerPort: 27017
    resources:
      requests:
        memory: "2Gi"
        cpu:    "2"
      limits:
        memory: "2Gi"
        cpu:    "2"
    volumeMounts:
      - name: db-storage
        mountPath: /data/db
  volumes:
    - name: db-storage
      persistentVolumeClaim:
        claimName: db-pvc
EOF

echo "=== creating Deployment and Service for microservice_b... ==="
cat > k8s-manifests/2-b-deploy-svc.yaml <<EOF
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
      - name: microservice-b
        image: ${IMAGE_B}
        env:
          - name: DB_HOST
            value: mikroserwis-db
          - name: DB_PORT
            value: "27017"
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: mongo-secret
                key: mongo-username
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: mongo-secret
                key: mongo-password
        ports:
          - containerPort: 5000
        resources:
          requests:
            memory: "1Gi"
            cpu: "1"
          limits:
            memory: "1Gi"
            cpu: "1"
---
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

echo "=== creating Deployment and LoadBalancer Service for microservice_a... ==="
cat > k8s-manifests/3-a-deploy-svc.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: microservice-a
spec:
  replicas: 3
  selector:
    matchLabels:
      app: microservice-a
  template:
    metadata:
      labels:
        app: microservice-a
    spec:
      containers:
      - name: microservice-a
        image: ${IMAGE_A}
        env:
          - name: SERVICE_B_URL
            value: http://microservice-b-svc:5000/hello
        ports:
          - containerPort: 5000
        resources:
          requests:
            memory: "500Mi"
            cpu: "0.5"
          limits:
            memory: "500Mi"
            cpu: "0.5"
---
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

echo "=== applying manifests and waiting for readiness... ==="
kubectl apply -f k8s-manifests

echo "=== waiting for database Pod to be Ready... ==="
kubectl wait --for=condition=Ready pod/microservice-db --timeout=60s

echo "=== waiting for microservice_b Deployment to rollout... ==="
kubectl rollout status deployment/microservice-b --timeout=60s

echo "=== waiting for microservice_a Deployment to rollout... ==="
kubectl rollout status deployment/microservice-a --timeout=60s

kubectl get all

echo "=== testing communication A -> B... ==="
kubectl port-forward svc/microservice-a-lb 8080:80

echo "=== script finished... ==="
