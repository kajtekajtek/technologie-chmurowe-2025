#!/bin/sh
# usage: ./zad2.sh [--clean] [image-repo] ["Full Name"]

set -euo pipefail

IMAGE_REPO="dockerhub-username/nginx-page"
FULL_NAME="Jan Kowalski"
CLEAN=false

if [ "${1:-}" = "--clean" ]; then
  CLEAN=true
  shift
fi
if [ "$#" -ge 1 ]; then
  IMAGE_REPO="$1"
  shift
fi
if [ "$#" -ge 1 ]; then
  FULL_NAME="$1"
  shift
fi

CLUSTER_NAME="nginx-cluster"
DEPLOY_NAME="nginx-deploy"
SERVICE_NAME="nginx-service"

KIND_BIN="$(go env GOPATH)/bin/kind"

cleanup() {
  echo "=== cleaning up... ==="
  $KIND_BIN delete cluster --name "$CLUSTER_NAME" || true
  docker rmi "${IMAGE_REPO}:v1.0" || true
  rm -rf app deployment.yaml service.yaml || true
}

[ "$CLEAN" = true ] && trap cleanup EXIT

echo "=== creating kubernetes cluser ($CLUSTER_NAME)... ==="
$KIND_BIN create cluster --name "$CLUSTER_NAME"

echo "=== creating a simple web page and a dockerfile... ==="
mkdir -p app
cat > app/index.html <<EOF
<!DOCTYPE html>
<html>
<head><title>Welcome</title></head>
<body>
  <h1>Welcome, $FULL_NAME!</h1>
</body>
</html>
EOF

cat > app/Dockerfile <<EOF
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EOF

echo "=== building and pushing $IMAGE_REPO:v1.0 image... ==="
docker build -t "${IMAGE_REPO}:v1.0" ./app
docker push "${IMAGE_REPO}:v1.0"

echo "=== creating deployment manifest with 3 replicas... ==="
cat > deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $DEPLOY_NAME
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-page
  template:
    metadata:
      labels:
        app: nginx-page
    spec:
      containers:
      - name: nginx
        image: ${IMAGE_REPO}:v1.0
        ports:
        - containerPort: 80
EOF

echo "=== creating Service manifest (NodePort)... ==="
cat > service.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE_NAME
spec:
  type: NodePort
  selector:
    app: nginx-page
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
EOF

echo "=== deploying the Deployment and Service... ==="
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl rollout status deployment/$DEPLOY_NAME
kubectl get pods,svc

NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "Page available on: http://$NODE_IP:30080"
curl --fail --silent http://$NODE_IP:30080 || echo "error: couldn't retrieve the web page..."

echo "=== scaling the deployment to 5 replicas... ==="
kubectl scale deployment/$DEPLOY_NAME --replicas=5
sleep 3

echo "=== checking replicas number... ==="
kubectl get deployment $DEPLOY_NAME
kubectl get pods -l app=nginx-page

echo "=== script finished ==="
