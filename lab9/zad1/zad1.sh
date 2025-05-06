#!/bin/sh
# usage ./zad1.sh [--clean] [image-repo-name]

set -euo pipefail

IMAGE_REPO="${1}"
CLUSTER_NAME="hello-cluster"
POD_NAME="hello-pod"
CONTAINER_NAME="hello-container"
KIND="$(go env GOPATH)/bin/kind"

# --clean flag for cleaning up after finished execution
CLEAN=false
if [[ "${1:-}" == "--clean" ]]; then
    CLEAN=true
    shift
    IMAGE_REPO="${1}"
fi

cleanup() {
    echo "=== removing kind cluster ${CLUSTER_NAME} ==="
    ${KIND} delete cluster --name "${CLUSTER_NAME}" || true
    echo "=== removing local Docker images... ==="
    #docker rmi "${IMAGE_REPO}:v1.0" "${IMAGE_REPO}:v2.0" || true

    echo "=== removing ./app directory and ${POD_NAME} manifest... ==="
    rm -rf ./app pod.yaml || true
}

if [[ "$CLEAN" == true ]]; then
    trap cleanup EXIT
fi

echo "=== creating kubernetes cluster... ==="
${KIND} create cluster --name "${CLUSTER_NAME}"

echo "=== creating the hello world app... ==="
mkdir -p app
cat > app/main.c <<'EOF'
#include <stdio.h>
int main() {
    printf("Hello World v1.0\n");
    return 0;
}
EOF

echo "=== creating the dockerfile... ==="
cat > app/Dockerfile <<'EOF'
FROM gcc:latest
WORKDIR /usr/src/app
COPY main.c .
RUN gcc -o hello main.c
ENTRYPOINT ["./hello"]
EOF

echo "=== building docker image... ==="
docker build -t "${IMAGE_REPO}:v1.0" ./app

echo "=== pushing docker image to repo... ==="
docker push "${IMAGE_REPO}:v1.0"

echo "=== loading ${IMAGE_REPO}:v1.0 into the ${CLUSTER_NAME}... ==="
$KIND load docker-image "${IMAGE_REPO}:v1.0" --name "${CLUSTER_NAME}"

echo "=== creating the ${POD_NAME} manifest... ==="
cat > pod.yaml <<EOF
apiVersion: v1
kind: Pod
metadata:
    name: ${POD_NAME}
spec:
    restartPolicy: Always
    containers:
    - name: ${CONTAINER_NAME}
      image: ${IMAGE_REPO}:v1.0
      command: ["/bin/sh", "-c", "sleep infinity"]
EOF

echo "=== deploying ${POD_NAME} in the cluster... ==="
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/${POD_NAME} --timeout=60s
kubectl get pods

echo "=== entering ${POD_NAME} console and running the app... === "
kubectl exec -it ${POD_NAME} -- /bin/sh -c "./hello"

echo "=== updating, building and pushing the image... ==="
cat > app/main.c <<'EOF'
#include <stdio.h>
int main() {
    printf("Hello World v2.0 — updated!\n");
    return 0;
}
EOF

docker build -t "${IMAGE_REPO}:v2.0" ./app
docker push "${IMAGE_REPO}:v2.0"

echo "=== loading ${IMAGE_REPO}:v2.0 into the ${CLUSTER_NAME}... ==="
$KIND load docker-image "${IMAGE_REPO}:v2.0" --name "${CLUSTER_NAME}"

echo "=== updating ${POD_NAME}... ==="
kubectl delete pod ${POD_NAME} --ignore-not-found
cat > pod.yaml << EOF
apiVersion: v1
kind: Pod
metadata:
  name: ${POD_NAME}
spec:
  restartPolicy: Always
  containers:
  - name: ${CONTAINER_NAME}
    image: ${IMAGE_REPO}:v2.0
    command: ["/bin/sh","-c","sleep infinity"]
EOF
kubectl apply -f pod.yaml
kubectl wait --for=condition=Ready pod/${POD_NAME} --timeout=60s

echo "=== entering updated ${POD_NAME} console and running the app... === "
kubectl exec -it ${POD_NAME} -- /bin/sh -c "./hello"

echo "=== finished ==="

