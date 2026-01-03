#!/bin/sh
set -e

echo "--- Starting Ghost with S3 Storage ---"

# Verify S3 credentials are set
if [ -z "$storage__s3__accessKeyId" ]; then
    echo "WARNING: storage__s3__accessKeyId is not set"
fi

if [ -z "$storage__s3__secretAccessKey" ]; then
    echo "WARNING: storage__s3__secretAccessKey is not set"
fi

if [ -n "$storage__s3__bucket" ]; then
    echo "S3 Bucket: ${storage__s3__bucket}"
    echo "S3 Region: ${storage__s3__region}"
fi

echo "--- Executing Original Ghost Entrypoint ---"
exec docker-entrypoint.sh "$@"
