#!/bin/sh

SOURCE_VOLUME="my_volume"
TARGET_VOLUME="secured_volume"
PASSWORD="psswd123"

ARCHIVE="${SOURCE_VOLUME}.tar"
ARCHIVE_ENC="${SOURCE_VOLUME}.tar.gpg"

echo "creating source volume $SOURCE_VOLUME"
docker volume create "$SOURCE_VOLUME"

echo "adding sample text file to $SOURCE_VOLUME"
docker run --rm -v "$SOURCE_VOLUME":/data busybox sh -c \
    "echo 'hello world' > /data/sample.txt"

echo "archiving volume's contents"
docker run --rm \
    -v "$SOURCE_VOLUME":/data \
    -v "${PWD}":/backup \
    busybox sh -c "tar -cvf /backup/$ARCHIVE /data"

echo "volume's archive: $ARCHIVE"

echo "encrypting archive with GPG. Password: $PASSWORD"
gpg --batch --yes --passphrase "$PASSWORD" -c "$ARCHIVE"

echo "encrypted archive: $ARCHIVE_ENC"

echo "removing .tar file"
rm -f "$ARCHIVE"

echo "creating target volume"
docker volume create "$TARGET_VOLUME"

echo "decrypting file $ARCHIVE_ENC"
gpg --batch --passphrase "$PASSWORD" -d "$ARCHIVE_ENC" > "$ARCHIVE"

if [ ! -f "$ARCHIVE" ]; then
    echo "error: couldn't decrypt file $ARCHIVE_ENC"
    exit 1
fi

echo "moving archived files to target volume $TARGET_VOLUME"
docker run --rm \
    -v "$TARGET_VOLUME":/data \
    -v "${PWD}":/backup \
    busybox sh -c "cd / && tar -xvf /backup/${ARCHIVE} --strip 1"

echo "removing $ARCHIVE"
rm -f "$ARCHIVE"