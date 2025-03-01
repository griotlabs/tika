#!/bin/bash

# substitute environment variables in tika-config.xml at runtime
sed -i "s|AWS_ENDPOINT_URL|$AWS_ENDPOINT_URL|g" /config/tika-config.xml
sed -i "s|AWS_ACCESS_KEY_ID|$AWS_ACCESS_KEY_ID|g" /config/tika-config.xml
sed -i "s|AWS_SECRET_ACCESS_KEY|$AWS_SECRET_ACCESS_KEY|g" /config/tika-config.xml
sed -i "s|GCS_PROJECT_ID|$GCS_PROJECT_ID|g" /config/tika-config.xml
sed -i "s|GCS_UPLOAD_BUCKET|$GCS_UPLOAD_BUCKET|g" /config/tika-config.xml
sed -i "s|GCS_CONTENT_BUCKET|$GCS_CONTENT_BUCKET|g" /config/tika-config.xml
sed -i "s|S3_UPLOAD_BUCKET|$S3_UPLOAD_BUCKET|g" /config/tika-config.xml
sed -i "s|S3_CONTENT_BUCKET|$S3_CONTENT_BUCKET|g" /config/tika-config.xml

exec java -cp "/tika-bin/*" org.apache.tika.server.core.TikaServerCli -h 0.0.0.0 -c "/config/tika-config.xml" "$@"
