FROM ghost:6-alpine

WORKDIR /var/lib/ghost

# Install the S3 storage adapter directly into the content directory structure
RUN npm install ghost-storage-adapter-s3 \
    && mkdir -p ./content.orig/adapters/storage \
    && cp -vr ./node_modules/ghost-storage-adapter-s3 ./content.orig/adapters/storage/s3

COPY docker-entrypoint-custom.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint-custom.sh

ENTRYPOINT ["docker-entrypoint-custom.sh"]
CMD ["node", "current/index.js"]
