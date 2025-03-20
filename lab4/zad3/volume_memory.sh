#!/bin/sh

volumes=$(docker volume ls -q)

if [ -z "$volumes" ]; then
    echo "No docker volumes found"
    exit 0
fi

for vol in $volumes; do
    usage=$(docker run --rm -v "$vol":/mnt busybox sh -c \
    "df -h /mnt | awk 'NR==3 {print \$4}'")

    echo "- $vol: $usage"
done